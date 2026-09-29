# Team 8 — Library Database

Use **[team8.sql](team8.sql)**. Please finish testing it before submission.

**Due Wednesday, September 30, 2026. Email the final SQL dump to uramamur@bcm.edu. GitHub is for sharing our work.**

## What is in the file?

- **14 tables** with keys and constraints.
- **fine_status:** a saved query (a view) that calculates whether a fine is paid.
- **save_room_reservation:** a saved SQL command (a procedure) that checks room bookings before saving.
- **No sample records.** The export used “no data,” so everyone must add their own test records.

The room command is inside this file because “Include stored routines” was selected when exporting. It is not a separate download.

## Changes made after Saleem's feedback

- Added `author` and `book_author`. Removed `book.author_name`.
- Added a unique calculated column to block two active loans for one copy. Do not enter `active_copy_id` yourself.
- Removed `paid_status` and `paid_date` from `fine`. Read them from `fine_status` instead:
  ```sql
  SELECT * FROM fine_status;
  ```
  Unpaid or partially paid means status 0 and no paid date. Fully covered means status 1, with the latest payment date.
- Added `save_room_reservation` for new bookings and edits. **Direct INSERT/UPDATE on room_reservations bypasses this check.** The application must use the procedure.

## How to open it on your computer

1. Install/start MySQL and connect DataGrip to your own server. Cloning GitHub does not connect you to Clark's database.
2. Download or pull the latest `team8.sql`. Make a copy for testing.
3. In that copy, remove the three whole lines containing `SQL_LOG_BIN` and the one whole line containing `GTID_PURGED`. They are server settings, not project tables.
4. Remove only this text wherever it appears: `` DEFINER=`root`@`localhost` ``. Keep the rest of the line. This lets the view and procedure belong to your importing account.
5. In your MySQL console, create and select a new, empty database:
   ```sql
   CREATE DATABASE team8_review;
   USE team8_review;
   ```
6. Run the entire cleaned file in that database. It contains DROP commands, so do not run it over work you need.
7. Run `SHOW FULL TABLES;`: expect 14 base tables and the fine_status view. Run `SHOW CREATE PROCEDURE save_room_reservation;` to check the procedure imported too.

## What still needs testing?

**Confirmed:** trying to lend the same copy twice without a return was rejected.

**Still to test:**
- Return the copy, then borrow it again: should succeed.
- Give one book two authors: should succeed.
- Add partial and full payments; edit/delete a payment; check `fine_status` each time.
- Add and edit room bookings through the procedure: overlapping times should fail; back-to-back times should work.
- Import the final dump into another empty database without errors.

For room bookings, the arguments are reservation ID, user ID, room ID, start, end. Use NULL for a new reservation, or its existing ID to edit. Example below assumes user 1 and room 1 exist; replace them with your actual IDs:
```sql
CALL save_room_reservation(
    NULL, 1, 1,
    '2026-09-30 14:00:00',
    '2026-09-30 15:00:00'
);
```
Call it on its own; it manages its own transaction.

Borrowing limits, automatic fines, copy-availability updates, and reminders are not implemented. This file is not the finished application.

## Finish and submit

After fixing/testing, export again with **Include stored routines checked**. Uncheck “no data” if the team is including sample records. Check the exported file for the same import settings above, test the exact final file, then commit/push it and email it before the deadline.

Pull before editing so you have the latest team changes.
