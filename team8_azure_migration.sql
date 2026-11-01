CREATE TABLE dbo.[notification] (
    [notification_id] int IDENTITY(1,1) NOT NULL,
    [user_id] int NOT NULL,
    [created_at] datetime2(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    [source] nvarchar(50) NOT NULL,
    [message] nvarchar(300) NOT NULL,
    [is_read] bit NOT NULL DEFAULT 0,
    PRIMARY KEY ([notification_id]),
    CONSTRAINT [notification_ibfk_1] FOREIGN KEY ([user_id]) REFERENCES dbo.[user] ([user_id])
);

CREATE TABLE dbo.[audit_log] (
    [log_id] int IDENTITY(1,1) NOT NULL,
    [logged_at] datetime2(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    [trigger_name] nvarchar(50) NOT NULL,
    [table_name] nvarchar(50) NOT NULL,
    [message] nvarchar(300) NOT NULL,
    PRIMARY KEY ([log_id])
);

CREATE INDEX [ix_notification_user_id] ON dbo.[notification] (user_id);

ALTER TABLE dbo.[payments] ADD [staff_id] int NULL
    CONSTRAINT [payments_ibfk_3] FOREIGN KEY REFERENCES dbo.[staff] ([staff_id]);
GO

CREATE OR ALTER TRIGGER dbo.trg_loan_checkout
ON dbo.[loan]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted WHERE return_date IS NULL)
        RETURN;

    IF EXISTS (
        SELECT 1 FROM inserted AS i
        JOIN dbo.[user] AS u ON u.user_id = i.user_id
        WHERE i.return_date IS NULL AND u.is_active = 0
    )
        THROW 51001, 'This account is deactivated and cannot borrow items', 1;

    IF EXISTS (
        SELECT 1 FROM inserted AS i
        JOIN dbo.copies AS c ON c.copy_id = i.copy_id
        WHERE i.return_date IS NULL AND c.is_active = 0
    )
        THROW 51002, 'This copy has been withdrawn and cannot be borrowed', 1;

    IF EXISTS (
        SELECT 1 FROM dbo.loan AS l
        JOIN dbo.[user] AS u ON u.user_id = l.user_id
        JOIN dbo.borrow_policy AS bp ON bp.is_faculty = u.is_faculty
        WHERE l.return_date IS NULL
          AND l.user_id IN (SELECT i.user_id FROM inserted AS i WHERE i.return_date IS NULL)
        GROUP BY l.user_id, bp.max_items
        HAVING COUNT(*) > bp.max_items
    )
        THROW 51003, 'Trying to borrow more books? Return one today and experience another book''s world!', 1;

    UPDATE c
    SET is_available = 0
    FROM dbo.copies AS c
    JOIN inserted AS i ON i.copy_id = c.copy_id
    WHERE i.return_date IS NULL;

    INSERT INTO dbo.audit_log (trigger_name, table_name, message)
    SELECT 'trg_loan_checkout', 'loan',
           CONCAT('Loan ', i.loan_id, ': copy ', i.copy_id, ' checked out to user ', i.user_id,
                  ', due ', CONVERT(char(10), i.due_date, 23))
    FROM inserted AS i
    WHERE i.return_date IS NULL;

    INSERT INTO dbo.notification (user_id, source, message)
    SELECT i.user_id, 'trg_loan_checkout',
           CONCAT('You borrowed "', COALESCE(b.title, m.title), '". It is due ',
                  CONVERT(char(10), i.due_date, 101), '.')
    FROM inserted AS i
    JOIN dbo.copies AS c ON c.copy_id = i.copy_id
    LEFT JOIN dbo.book AS b ON b.book_id = c.book_id
    LEFT JOIN dbo.media AS m ON m.media_id = c.media_id
    WHERE i.return_date IS NULL;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_loan_return
ON dbo.[loan]
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.fine (loan_id, amount)
    SELECT i.loan_id, 5 + DATEDIFF(day, i.due_date, i.return_date) / 7
    FROM inserted AS i
    JOIN deleted AS d ON d.loan_id = i.loan_id
    WHERE d.return_date IS NULL
      AND i.return_date > i.due_date
      AND NOT EXISTS (SELECT 1 FROM dbo.fine AS f WHERE f.loan_id = i.loan_id);

    UPDATE c
    SET is_available = CASE WHEN EXISTS (
            SELECT 1 FROM dbo.loan AS l WHERE l.copy_id = c.copy_id AND l.return_date IS NULL
        ) THEN 0 ELSE 1 END
    FROM dbo.copies AS c
    WHERE c.copy_id IN (SELECT copy_id FROM inserted UNION SELECT copy_id FROM deleted);

    INSERT INTO dbo.audit_log (trigger_name, table_name, message)
    SELECT 'trg_loan_return', 'loan',
           CONCAT('Loan ', i.loan_id, ': copy ', i.copy_id, ' returned',
                  CASE WHEN f.fine_id IS NOT NULL THEN CONCAT(', fine $', f.amount) ELSE '' END)
    FROM inserted AS i
    JOIN deleted AS d ON d.loan_id = i.loan_id
    LEFT JOIN dbo.fine AS f ON f.loan_id = i.loan_id
    WHERE d.return_date IS NULL AND i.return_date IS NOT NULL;

    INSERT INTO dbo.notification (user_id, source, message)
    SELECT i.user_id, 'trg_loan_return',
           CONCAT('You returned "', COALESCE(b.title, m.title), '".',
                  CASE WHEN f.fine_id IS NOT NULL
                       THEN CONCAT(' It was late, so a fine of $', f.amount, ' was added.')
                       ELSE '' END)
    FROM inserted AS i
    JOIN deleted AS d ON d.loan_id = i.loan_id
    JOIN dbo.copies AS c ON c.copy_id = i.copy_id
    LEFT JOIN dbo.book AS b ON b.book_id = c.book_id
    LEFT JOIN dbo.media AS m ON m.media_id = c.media_id
    LEFT JOIN dbo.fine AS f ON f.loan_id = i.loan_id
    WHERE d.return_date IS NULL AND i.return_date IS NOT NULL;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_room_reservations_overlap
ON dbo.[room_reservations]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted AS i
        JOIN dbo.room_reservations AS r
          ON r.room_id = i.room_id
         AND r.reservation_id <> i.reservation_id
         AND r.start_time < i.end_time
         AND r.end_time > i.start_time
    )
        THROW 51004, 'Room is already booked during that time', 1;

    INSERT INTO dbo.audit_log (trigger_name, table_name, message)
    SELECT 'trg_room_reservations_overlap', 'room_reservations',
           CONCAT('Reservation ', i.reservation_id, ': room ', i.room_id,
                  ' booked by user ', i.user_id, ', no overlap')
    FROM inserted AS i;

    INSERT INTO dbo.notification (user_id, source, message)
    SELECT i.user_id, 'trg_room_reservations_overlap',
           CONCAT('Room ', r.room_number, ' is booked for you on ',
                  CONVERT(char(16), i.start_time, 120), '.')
    FROM inserted AS i
    JOIN dbo.room AS r ON r.room_id = i.room_id;
END;
GO

SELECT
    (SELECT COUNT(*) FROM sys.tables WHERE name IN ('notification', 'audit_log')) AS new_tables,
    (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('dbo.payments') AND name = 'staff_id') AS staff_id_added,
    (SELECT COUNT(*) FROM sys.triggers WHERE name LIKE 'trg_%') AS triggers;
