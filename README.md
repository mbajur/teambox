# Teambox
## ⚙️ About This Project

This project is a full reimagining of Teambox — an open-source project management and collaboration tool originally developed by Redbooth and last updated in 2012.

While Teambox has been dormant for over a decade, its spirit and ideas live on. This repository aims to revive and modernize the project using current tools and best practices, while honoring its roots.

## ✨ Goals & Vision

This is not a direct continuation — it’s a ground-up rewrite. The objectives of this revamped version include:

### Core Architecture
- [x] Upgrade to Rails 8
- [ ] Refactor as a mountable Rails engine
- [ ] Support installation into existing Rails apps

### Frontend
- [ ] Replace legacy UI with Tailwind CSS
- [ ] Implement fully responsive design (RWD)
- [x] Integrate Hotwire (Turbo + Stimulus) for interactivity
- [ ] Remove legacy JavaScript dependencies (jQuery, Backbone, etc.)

### Extensibility
- [ ] Modularize major features into optional plugins
- [ ] Design plugin API for extending or replacing core functionality
- [ ] Provide minimal default setup with no preloaded features
- [ ] Document how to write and load plugins

### Functionality (Core Features to Reintroduce)
- [ ] User authentication and roles
- [ ] Projects and task management
- [ ] Comments and discussions
- [ ] Basic notifications (Turbo Stream or similar)
- [ ] Minimal UI for core features

### Developer Experience
- [ ] Use modern Rails conventions and patterns
- [ ] Provide development setup instructions and seed data
- [ ] Write specs for all core modules
- [ ] Ensure engine is testable in isolation and within a host app
- [x] CI / Specs suite

## 🎓 Tribute

This project is inspired by and pays tribute to the original Teambox and its creators at Redbooth. Without their foundational work, this project wouldn't exist.
