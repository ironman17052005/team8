# Team 8 — Library Database

Checkpoint 2 working database. Due **Wednesday, September 30, 2026, by email**.

## Start here

Use **[team8.sql](team8.sql)**. It contains 12 tables, 13 foreign keys, and basic constraints. It currently has no sample rows or triggers. Importing it on another computer still needs testing.

**Ignore `team8_progress.sql`. It is an empty file from an earlier export attempt.** It can be deleted during cleanup; it is not the submission file.

## Checkpoint 2 requirements

Our class notes list:
- Work as a team and choose a DBMS: we chose MySQL.
- Build the schema with entities, attributes, relationships, and constraints.
- Generate one database backup or SQL dump.
- Email the final file by September 30. GitHub is for teamwork, not the submission itself.

“Acquiring domain knowledge” appears under Checkpoint 1. It means understanding the library's real rules: who borrows, how copies work, due dates, waitlists, fines, and rooms. The notes do not list a separate knowledge report for Checkpoint 2.

The full project also needs authentication, data-entry forms, at least two triggers, three queries, and three reports. The Checkpoint 2 notes do not explicitly require all of those now. Confirm the timing of business-rule enforcement with the instructor if needed; do not call an unenforced rule complete.

## What we built

We are using submitted V1 as the base, with these agreed changes:
- Students and faculty use `user`; employees and admins use `staff`.
- `is_faculty`: 0 = student, 1 = faculty. No general-public role in this version.
- Books and media stay separate. `media.is_dvd`: 1 = DVD, 0 = Chromebook.
- Author names are in `book.author_name`; there is no separate author table.
- Each physical copy belongs to exactly one book or media title.
- A loan points to a physical copy, so the same copy can be borrowed again after return.
- `waitlist` replaces holds. Room reservations use start and end times.

| Tables | Purpose |
| --- | --- |
| user, staff | Borrowers and library workers |
| book, media | Catalog titles |
| copies | Individual physical items |
| loan | Borrowing history |
| waitlist | Requests for unavailable titles |
| room, room_reservations | Rooms and bookings |
| fine, payments, receipts | Charges and payment records |

Some sections of the team document still describe older alternatives such as ITEMS, AUTHORS, and BORROW_RULES. They do not match this SQL. Review the differences together before changing the design.

## Test the import on your computer

1. Use MySQL, with a version that enforces CHECK constraints (MySQL 8.0.16 or newer). DataGrip is the editor; MySQL is the database server.
2. Download `team8.sql` and make a local copy named `team8_test.sql`.
3. In that copy, remove the **three whole lines containing `SQL_LOG_BIN`** and the **one whole line containing `GTID_PURGED`**. These are server replication settings, not library tables. Removing them avoids unnecessary import permissions and transaction-history conflicts.
4. In a connected MySQL console, run:
   ```sql
   CREATE DATABASE team8_review;
   USE team8_review;
   ```
   Use a new, unused database name if that name already exists.
5. In the same console, paste and run the entire cleaned file after selecting that database. The dump contains DROP TABLE commands: use this empty test database, not a database containing work you need.
6. Run `SHOW TABLES;`. Expect 12 tables. Check the import log for errors.

These steps describe a test to perform; a successful import has not yet been verified.

## Remaining team checklist

- [ ] Test a clean import and check all 12 tables and 13 foreign keys.
- [ ] Add a few temporary test rows. Confirm duplicate emails, missing referenced users, invalid dates, and a copy with both book_id and media_id are rejected.
- [ ] Review the schema against the agreed mini-world and fix required differences.
- [ ] Resolve the business rules below: implement those required now, and clearly document what is deferred.
- [ ] Export the final database again and test that exact final file in another empty database.
- [ ] Email the final SQL dump before the deadline.

### Business rules not enforced by the current file

- Student: maximum 3 active loans, 20 days. Faculty: maximum 6, 30 days, following V1.
- Only available copies can be borrowed; one active loan per copy; update availability on borrow/return.
- No overlapping reservations for the same room.
- Waitlist only when no copy is available, served by request_time then waitlist_id. No pickup deadline is stored in this version.
- Fine calculation ($5 plus $1 per week late), payment totals, payer matching, and paid status/date consistency. Agree how partial weeks count.
- Two-day reminders and staff access permissions. Time passing alone does not fire a normal insert/update/delete trigger.
- Password columns must contain application-generated password hashes, not plain passwords.

Basic keys and CHECK constraints already exist, but they do not enforce these cross-row or application rules.

## Export and share future changes

Exporting creates a file; GitHub does not automatically copy your running database.

For a portable export, use mysqldump options `--set-gtid-purged=OFF --single-transaction`. Include `--routines --events --triggers` if the final implementation uses those objects. Export only the project database.

Before editing, pull the latest GitHub changes. Save the updated dump as `team8.sql` inside your local project folder. In DataGrip, commit that file with a clear message, then push. If Git reports a conflict, resolve it with the team before pushing; do not force-push over another person's work.

Share this repository link with teammates. The empty old file is optional cleanup, not a blocker.
