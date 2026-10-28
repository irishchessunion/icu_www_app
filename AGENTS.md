# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) and other AI agents when working with code in this repository.

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

# Run the app (web + MySQL) at http://localhost:3000
docker-compose up          # or -d for detached
docker-compose down        # stop; add -v to also wipe volumes/reset the db

# Tests
docker-compose run --rm test                                              # full suite
docker-compose run --rm test bundle exec rspec spec/models/               # a directory
docker-compose run --rm test bundle exec rspec spec/models/user_spec.rb:42  # single test by line
docker-compose run --rm -e STRIPE=1 test                                  # include the slow Stripe checkout specs (skipped by default)

# Console / migrations / shell
docker-compose run --rm web bundle exec rails console
docker-compose run --rm web bundle exec rails db:migrate
docker-compose run --rm web bash

docker-compose logs -f web
docker-compose build web   # rebuild after Gemfile changes
```

Docker notes:
- Docker's MySQL is published on host port **3307**, so it can run alongside a MySQL (3306) already running on the Mac. Inside Docker, services still use the standard ports.
- The image builds natively for the machine (arm64 on Apple Silicon, amd64 on CI). Don't pin `--platform=linux/amd64`: under emulation Chromium crashes and every JS feature spec fails.
- The `test` service is in a `test` profile, so `docker-compose up` doesn't start it; `docker-compose run --rm test` works without naming the profile.
- Running the specs directly on the Mac (`bundle exec rspec`) is about twice as fast as in Docker. To use one `config/database.yml` for both, read the connection settings from the env vars that `web` and `test` set, with local defaults, e.g. `host: <%= ENV.fetch("DATABASE_HOST", "127.0.0.1") %>` (likewise `DATABASE_USERNAME` and `DATABASE_PASSWORD`).

Tests use RSpec + Capybara/Selenium (feature specs) with `database_cleaner` (transaction strategy normally, truncation for `:js` specs — see `spec/rails_helper.rb`). Spec helpers `login(user_or_roles)` and `logout` are globally available in feature specs.

## Architecture

### Auth & authorization
Auth is hand-rolled, not Devise — `User` stores `encrypted_password`/`salt` directly and implements its own `valid_password?`/`encrypt_password`. Authorization is role-based via CanCanCan: roles live as a space-separated string on `User` (`User::ROLES`), and all permission logic is centralized in `app/models/ability.rb` (one large `Ability#initialize`, plus `grant_full_event_permissions` shared between event creators/organisers/treasurers). When adding a feature that needs permission checks, extend `Ability` rather than sprinkling role checks through controllers.

### Public vs admin surface
`config/routes.rb` defines a public-facing resource set (mostly `index`/`show`, read-heavy) and a parallel `namespace :admin` with the fuller CRUD for the same models (e.g. `resources :clubs, only: [:index, :show]` publicly vs `resources :clubs, only: [:new, :create, :edit, :update]` under admin). Controllers/views mirror this split (`app/controllers/admin/...`, `app/views/admin/...`). When adding a resource, expect to touch both sides.

### Style Guide / CSS / Theme
- Check existing project CSS and Bootstrap 3.0.2 classes and components before creating new classes or rules. Refer to the documentation (https://bootstrapdocs.com/v3.0.2/docs/) if needed.
- Add custom CSS and rules to `app/assets/stylesheets/application.css` only when existing project or framework styles cannot meet the requirement. Never use `!important` flags.
- Inherit typography. Let the active theme determine font sizes. Override `font-size` only when necessary, and always use `em`, never `px`, so it scales with theme values.
- Use semantic HTML. Prefer widely supported elements that match the content’s meaning (`article`, `header`, `footer`, `nav`, lists, etc.) over nested div wrappers.
- Write any custom CSS desktop-first. Put desktop styles in the base rules and use `max-width` media queries for smaller-screen overrides. Follow Bootstrap 3.0.2 breakpoints.
- Keep CSS selectors structural. Prefer a component class with child selectors, e.g. `.results-item > header` and `.results-item > footer`, rather than `.results-item-header` and `.results-item-footer`. Add child classes only when needed to distinguish their purpose or behaviour.
- Support every theme. Users can toggle between all Bootswatch 3.2 (https://bootswatch.com/3/) themes. Flatly is the default and is used by most users and all guests. Use the shared variables defined in each theme’s `app/assets/stylesheets/variables_{theme}.css`, instead of hard-coded colours to preserve theme compatibility.

### Hotwire (Turbo & Stimulus)
`turbo-rails` (~> 2.0) and `stimulus-rails` (~> 1.3) are loaded from `app/views/layouts/application.html.haml` as two ES module scripts: `turbo` standalone, plus `hotwire.js` (a sprockets bundle containing stimulus and boot). They cannot be combined into one file as turbo.js and stimulus.js declare conflicting top-level helpers, which breaks terser minification. Turbo Drive is **globally disabled** in the bundle (`Turbo.session.drive = false`), so all links/forms keep their current full-page/jQuery-UJS behaviour until a feature explicitly opts in. Stimulus is started in the bundle and exposed as `window.Stimulus`. Register controllers from additional files required into `app/assets/javascripts/hotwire.js`. Migrate features to Hotwire page-by-page only when requested rather than removing the legacy `jquery_ujs` behaviour.

### Shared model behaviour via concerns (`app/models/concerns/`)
Several cross-cutting behaviors are implemented as concerns rather than gems:
- **Journalable** — opt-in audit log. A model calls `journalize(columns, path)` to declare which columns are tracked; changes are recorded as `JournalEntry` records via an explicit `.journal(action, by, ip)` call (not an automatic callback) with diffs computed by `Util::Diff`.
- **Pageable** — custom pagination (not Kaminari/WillPaginate). `Model.paginate(matches, params, path)` returns a `Pager` used directly in views.
- **Payable** — shared state machine for anything that can be paid for (`Item`, `Cart`): `status` (`unpaid`/`paid`/`part_refunded`/`refunded`) and `payment_method` (`stripe`/`paypal`/`cheque`/`cash`/`free`), with generated `active?`/`paid?`/etc. predicate methods and scopes.
- Others: `Cartable`, `Accessible`, `Expandable`, `Geocodable`, `Normalizable`, `Remarkable`.

### Payments (Cart / Item / Fee)
`Fee` is STI (`Fee::Subscription`, `Fee::Entry`, `Fee::Other`) defining what can be bought (membership subs, tournament entries, etc.); `Item` (also STI-mirrored: `Item::Subscription`, `Item::Entry`, `Item::Other`) is a purchased instance of a `Fee` belonging to a `Cart`. Checkout goes through Stripe (`payments` controller: `shop`/`cart`/`card`/`charge`/`confirm`/`completed`) or offline via admin `CashPayment`. Refunds and payment errors are tracked separately (`Refund`, `PaymentError`, `MailEvent`/`MailControl` for related email).

### Legacy data
The site's data was converted once, in 2014, from the ICU's old (`www1`) site and database. The conversion code has been removed (it's in git history), but `Ability` and `Global::SOURCES` (`www1`/`www2`) still distinguish records by origin. All that's left in `lib/icu/legacy/` is `check.rb`, run with `bin/rake sync:check`, which reports broken links between players, users, clubs and games in the current database.

### Global constants
`app/models/global.rb` centralizes app-wide lists used by routing and views: static ICU document/page names (`ICU_DOCS`, `ICU_PAGES`), help page names (`HELP_PAGES`), and shared validators (`Global.valid_url?`, `Global.valid_email?`). Routes for these pages are generated dynamically from these lists in `config/routes.rb`, so adding a new static ICU/help page is a matter of adding it to the relevant `Global` list plus a view, not a new route.

### i18n
Two locales (`en`, `ga`) with fallback enabled; locale files are auto-loaded from `config/locales/**/*.yml`.

### Deployment
Capistrano (`Capfile`, `config/deploy.rb`), deploying to `/var/apps/www`; `config/database.yml` and `config/secrets.yml` are linked (per-server) files, not checked in.