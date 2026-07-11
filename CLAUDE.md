# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Source for version 2 of the Irish Chess Union's web site (www.icu.ie) — a Rails 7 app. See the [wiki](https://github.com/sanichi/icu_www_app/wiki) for server setup/maintenance instructions beyond initial dev setup.

Views are written in **HAML** (`.html.haml`), not ERB — use HAML syntax/whitespace-significant indentation when editing or adding views. Tests are written in **RSpec** (models, controllers, requests, and Capybara/Selenium feature specs) — there is no Minitest in this codebase.

## Commands

All development happens through Docker Compose; there is no documented bare-metal setup.

```bash
# One-time setup
cp config/examples/database-docker.yml config/database.yml
docker-compose build
docker-compose run --rm web bundle exec rails db:create db:migrate db:seed

# Run the app (web + MySQL + Redis) at http://localhost:3000
docker-compose up          # or -d for detached
docker-compose down        # stop; add -v to also wipe volumes/reset the db

# Tests
docker-compose run --rm test                                              # full suite
docker-compose run --rm test bundle exec rspec spec/models/               # a directory
docker-compose run --rm test bundle exec rspec spec/models/user_spec.rb:42  # single test by line

# Console / migrations / shell
docker-compose run --rm web bundle exec rails console
docker-compose run --rm web bundle exec rails db:migrate
docker-compose run --rm web bash

docker-compose logs -f web
docker-compose build web   # rebuild after Gemfile changes
```

Tests use RSpec + Capybara/Selenium (feature specs) with `database_cleaner` (transaction strategy normally, truncation for `:js` specs — see `spec/rails_helper.rb`). Spec helpers `login(user_or_roles)` and `logout` are globally available in feature specs.

### Dual Rails version (`Gemfile.next`)

The app is mid-upgrade from Rails 8.0 to 8.1. `Gemfile.next` is a symlink to `Gemfile`; the `next_rails` gem (`NextRails.next?`) checks which filename Bundler was invoked with (`File.basename(__FILE__) == "Gemfile.next"`) and switches gem versions/config load_defaults accordingly (see `config/application.rb`). To exercise the "next" version locally, invoke Bundler with `BUNDLE_GEMFILE=Gemfile.next`. Don't remove this dual-boot scaffolding without checking whether the upgrade is complete.

## Architecture

### Auth & authorization
Auth is hand-rolled, not Devise — `User` stores `encrypted_password`/`salt` directly and implements its own `valid_password?`/`encrypt_password`. Authorization is role-based via CanCanCan: roles live as a space-separated string on `User` (`User::ROLES`), and all permission logic is centralized in `app/models/ability.rb` (one large `Ability#initialize`, plus `grant_full_event_permissions` shared between event creators/organisers/treasurers). When adding a feature that needs permission checks, extend `Ability` rather than sprinkling role checks through controllers.

### Public vs admin surface
`config/routes.rb` defines a public-facing resource set (mostly `index`/`show`, read-heavy) and a parallel `namespace :admin` with the fuller CRUD for the same models (e.g. `resources :clubs, only: [:index, :show]` publicly vs `resources :clubs, only: [:new, :create, :edit, :update]` under admin). Controllers/views mirror this split (`app/controllers/admin/...`, `app/views/admin/...`). When adding a resource, expect to touch both sides.

### Shared model behaviour via concerns (`app/models/concerns/`)
Several cross-cutting behaviors are implemented as concerns rather than gems:
- **Journalable** — opt-in audit log. A model calls `journalize(columns, path)` to declare which columns are tracked; changes are recorded as `JournalEntry` records via an explicit `.journal(action, by, ip)` call (not an automatic callback) with diffs computed by `Util::Diff`.
- **Pageable** — custom pagination (not Kaminari/WillPaginate). `Model.paginate(matches, params, path)` returns a `Pager` used directly in views.
- **Payable** — shared state machine for anything that can be paid for (`Item`, `Cart`): `status` (`unpaid`/`paid`/`part_refunded`/`refunded`) and `payment_method` (`stripe`/`paypal`/`cheque`/`cash`/`free`), with generated `active?`/`paid?`/etc. predicate methods and scopes.
- Others: `Cartable`, `Accessible`, `Expandable`, `Geocodable`, `Normalizable`, `Remarkable`.

### Payments (Cart / Item / Fee)
`Fee` is STI (`Fee::Subscription`, `Fee::Entry`, `Fee::Other`) defining what can be bought (membership subs, tournament entries, etc.); `Item` (also STI-mirrored: `Item::Subscription`, `Item::Entry`, `Item::Other`) is a purchased instance of a `Fee` belonging to a `Cart`. Checkout goes through Stripe (`payments` controller: `shop`/`cart`/`card`/`charge`/`confirm`/`completed`) or offline via admin `CashPayment`. Refunds and payment errors are tracked separately (`Refund`, `PaymentError`, `MailEvent`/`MailControl` for related email).

### Legacy data (`lib/icu/legacy/`)
This code performed a one-time sync from the ICU's old (`www1`) site/database into this one. The sync is complete and `Ability`/`Global::SOURCES` (`www1`/`www2`) still distinguish records by origin, but `lib/icu/legacy/database.rb`'s DB connection methods now deliberately `raise` — the legacy DB is no longer reachable/used. Don't attempt to "fix" these raises; the legacy sync is intentionally disabled.

### Global constants
`app/models/global.rb` centralizes app-wide lists used by routing and views: static ICU document/page names (`ICU_DOCS`, `ICU_PAGES`), help page names (`HELP_PAGES`), and shared validators (`Global.valid_url?`, `Global.valid_email?`). Routes for these pages are generated dynamically from these lists in `config/routes.rb`, so adding a new static ICU/help page is a matter of adding it to the relevant `Global` list plus a view, not a new route.

### i18n
Two locales (`en`, `ga`) with fallback enabled; locale files are auto-loaded from `config/locales/**/*.yml`.

### Deployment
Capistrano (`Capfile`, `config/deploy.rb`), deploying to `/var/apps/www`; `config/database.yml` and `config/secrets.yml` are linked (per-server) files, not checked in.