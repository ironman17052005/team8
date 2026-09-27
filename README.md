# Team 8 — Library Database

Use **[team8.sql](team8.sql)**. The tables are created, but we still need someone to check the logic and test the import.

Ignore `team8_progress.sql` — that file is empty.

## Checkpoint 2

Due **Wednesday, September 30, 2026**, by email to **uramamur@bcm.edu**.

We need MySQL tables with the entities, attributes, relationships, and constraints, then one SQL dump to submit. The checkpoint instructions do not separately ask for the website, reports, or triggers.

## Current version

Based on V1 with a few changes:
- Books and media are separate. Copies belong to one book or media title.
- Loans use a specific copy.
- Waitlist replaces holds. Room reservations are separate.
- Author name is inside the book table.
- Students/faculty use `user`; employees/admins use `staff`.

There are **12 tables and 13 foreign keys**. No sample data yet. Borrowing limits, room overlap checks, and automatic fines are not enforced. Review what the required constraints cover before calling it finished.

## What is left

1. Check the tables and constraints against our agreed plan. Some older sections of the Google Doc do not match the SQL.
2. Test importing the dump into a **new, empty database**. The file replaces tables with matching names.
3. Fix any errors, then export and test the final file.
4. Email that one file before the deadline.

For the import test, use a copy of `team8.sql`. Remove the three whole lines containing `SQL_LOG_BIN` and the one containing `GTID_PURGED`; these are server settings. Create and select an empty database, run the file, then run `SHOW TABLES;` — expect 12 tables.

Pull the latest GitHub changes before editing. After database changes, export again, save as `team8.sql` in the project folder, commit, and push.
