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
- As soon as you start typing, saved expense types that start with what
  you've typed are suggested above the input. Tapping a suggestion fills
  in the type followed by a space, ready for the amount.

### Expense types

Available from the ⋮ menu on the Home page (**Expense Types**).

- Add expense types such as `fare`, `outing` or `grocery`. These are
  used as suggestions when adding expenses.
- The input only accepts letters (no numbers, spaces or symbols), and
  always saves the type in lowercase. Duplicate names are rejected.
- Edit a type's name or delete a type. This only changes the suggestion
  list: expenses already saved under that type are left as they are.
- When upgrading from a version before 1.3.0, the types already used in
  your expenses are added to the list automatically.

### Current and previous periods

- Expenses always belong to the open "current" period.
- The `close` button on the Home page closes the current period (turning
  it into a "previous" period) and immediately starts a new, empty
  current period. It asks for confirmation first, and is disabled when
  the current period has no expenses.

### History page

- Filter expenses by date range with the **From** and **To** date
  pickers, then tap **Apply**. **From** defaults to the date the current
  period started and **To** to today; both end dates are included.
- Shows the total spent on each expense type in the selected range
  (sorted by type name), across current and previous periods, followed
  by the overall total for the range.
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
- `sqflite` for local persistent storage (periods, expenses and expense types
  tables)
- `provider` for state management
- `intl` for currency and date formatting
- `csv` for export/import file parsing, `file_saver` to write the
  export to Downloads, `file_picker` to select a file to import

## Setup

See [SETUP.md](SETUP.md) for setting up the Flutter/Android toolchain
and running the app. See [SPEC.md](SPEC.md) for the original feature
spec this project was built from.
