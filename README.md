# expense_tracker

A minimal Android expense tracker built with Flutter. All amounts are in
BDT (৳). This project is vibecoded — built by prompting Claude Code
rather than writing the implementation by hand.

## Features

### Adding expenses

- Log an expense with a short text command in the form
  `<expense_type> <amount>`, e.g. `fare 60`.
- Uppercase letters are converted to lowercase as you type (`Fare 60`
  is entered as `fare 60`).
- Every submission is saved as its own entry, even for a type already
  used in the period (`fare 100` then `fare 20` stays as two separate
  `fare` entries).
- Amounts can be negative, to record adjustments/corrections against an
  existing type (e.g. `fare -10`).

### Current and previous periods

- Expenses always belong to the open "current" period.
- The `close` button on the Home page closes the current period (turning
  it into a "previous" period) and immediately starts a new, empty
  current period. It's disabled when the current period has no expenses.

### History page

- Filter expenses by date range with the **From** and **To** date
  pickers, then tap **Apply**. Defaults to the last 30 days (today minus
  30 days through today); both end dates are included.
- Shows every expense in the selected range as its own entry, newest
  first, across current and previous periods, along with the total
  spent in that range.
- **Clear History**: deletes the *n* oldest previous periods (and their
  expenses) at once, after confirming how many to remove.

### Stats page

Computed across every period, current through oldest:

- Total expense amount for each period.
- Total expense amount for each expense type.
- Average expense amount per period for each expense type, rounded up
  to the nearest integer.
- Average total expense per period, across all periods.

### Export / Import (backup & restore)

Available from the ⋮ menu on the Home page.

- **Export CSV**: writes every period (current through oldest) and its
  expenses to a CSV file in the phone's Downloads folder.
- **Import CSV**: pick a CSV file (in the same format Export produces)
  and replace all current and previous expenses with its contents.
  Asks for confirmation first, since this can't be undone, and leaves
  existing data untouched if the file is malformed.

## Tech stack

- Flutter (managed via FVM — see [SETUP.md](SETUP.md))
- `sqflite` for local persistent storage (periods and expenses tables)
- `provider` for state management
- `intl` for currency and date formatting
- `csv` for export/import file parsing, `file_saver` to write the
  export to Downloads, `file_picker` to select a file to import

## Setup

See [SETUP.md](SETUP.md) for setting up the Flutter/Android toolchain
and running the app. See [SPEC.md](SPEC.md) for the original feature
spec this project was built from.
