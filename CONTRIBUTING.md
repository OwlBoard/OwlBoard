# Contributing to OwlBoard

Thank you for your interest in contributing to OwlBoard! This document provides guidelines and instructions for contributing.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Submitting Changes](#submitting-changes)
- [Code Style](#code-style)
- [Testing](#testing)
- [Documentation](#documentation)

## 🚀 Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/OwlBoard.git
   cd OwlBoard
   ```
3. **Run the setup script**:
   ```bash
   ./setup.sh
   ```

## 💻 Development Setup

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Git
- OpenSSL
- Your favorite code editor

### Quick Development Start

```bash
# Use the Makefile for convenience
make setup
make dev

# Or manually
./setup.sh --dev
docker compose up --build -d
```

### Service-Specific Development

Each service can be developed independently:

```bash
# Restart a specific service after changes
make restart-service SERVICE=user_service

# View logs for a specific service
make logs-service SERVICE=user_service

# Rebuild a specific service
docker compose up --build -d user_service
```

## 🔄 Making Changes

### Branching Strategy

We follow Gitflow branching:

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Urgent production fixes
- `release/*` - Release preparation

### Create a Feature Branch

```bash
# Update your local develop branch
git checkout develop
git pull origin develop

# Create your feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ... edit files ...

# Commit your changes
git add .
git commit -m "feat: add amazing feature"
```

### Commit Message Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```bash
git commit -m "feat(user-service): add user authentication"
git commit -m "fix(chat): resolve WebSocket connection issue"
git commit -m "docs: update deployment guide"
```

## 📤 Submitting Changes

### Before Submitting

1. **Test your changes**:
   ```bash
   make verify
   docker compose ps
   ```

2. **Check logs for errors**:
   ```bash
   make logs
   ```

3. **Update documentation** if needed

4. **Run code formatters/linters** (if available for your service)

### Create a Pull Request

1. **Push your branch**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Open a Pull Request** on GitHub:
   - Set base branch to `develop`
   - Provide a clear title and description
   - Link any related issues
   - Add screenshots/videos if applicable

3. **Address review feedback**:
   ```bash
   # Make requested changes
   git add .
   git commit -m "fix: address review feedback"
   git push origin feature/your-feature-name
   ```

### Pull Request Checklist

- [ ] Code follows project style guidelines
- [ ] Changes are tested locally
- [ ] Documentation is updated
- [ ] Commit messages follow convention
- [ ] No merge conflicts with develop
- [ ] All services start successfully
- [ ] No breaking changes (or clearly documented)

## 🎨 Code Style

### Python Services (User, Chat, Comments)

- Follow [PEP 8](https://pep8.org/)
- Use type hints where possible
- Maximum line length: 100 characters
- Use meaningful variable names

```python
# Good
def get_user_by_id(user_id: int) -> User:
    """Retrieve a user by their ID."""
    return db.query(User).filter(User.id == user_id).first()

# Bad
def get(id):
    return db.query(User).filter(User.id==id).first()
```

### Go Service (Canvas)

- Follow [Effective Go](https://golang.org/doc/effective_go)
- Run `go fmt` before committing
- Use meaningful package and variable names

```go
// Good
func GetCanvasById(id string) (*Canvas, error) {
    // implementation
}

// Bad
func get(i string) interface{} {
    // implementation
}
```

### JavaScript/TypeScript (Frontends)

- Use ESLint and Prettier
- Prefer `const` over `let`
- Use arrow functions for callbacks
- Maximum line length: 100 characters

```typescript
// Good
const fetchUserData = async (userId: number): Promise<User> => {
    const response = await fetch(`/api/users/${userId}`);
    return response.json();
};

// Bad
function fetchUserData(userId) {
    return fetch('/api/users/' + userId).then(r => r.json());
}
```

### Docker & Infrastructure

- Use multi-stage builds
- Minimize image layers
- Don't include secrets in images
- Document environment variables

## 🧪 Testing

### Running Tests

```bash
# Run all tests (when implemented)
make test

# Run service-specific tests
docker compose exec user_service pytest
docker compose exec comments_service pytest
```

### Writing Tests

- Write unit tests for new features
- Write integration tests for API endpoints
- Test error handling
- Test edge cases

## 📚 Documentation

### When to Update Documentation

- Adding new features
- Changing API endpoints
- Modifying configuration
- Changing deployment process
- Fixing bugs that affect usage

### Documentation Files

- `README.md` - Main project overview
- `QUICKSTART.md` - Quick start guide
- `DEPLOYMENT.md` - Deployment instructions
- `ARCHITECTURE_SECURITY_REPORT.md` - Architecture details
- Service-specific READMEs in each service directory

## 🐛 Reporting Bugs

### Before Reporting

1. **Search existing issues** to avoid duplicates
2. **Try to reproduce** the bug in a clean environment
3. **Check logs** for error messages

### Bug Report Template

```markdown
## Description
Brief description of the bug

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. See error

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., Ubuntu 22.04]
- Docker version: [e.g., 20.10.17]
- Browser: [e.g., Chrome 96] (if applicable)

## Logs
```
Relevant log output
```

## Screenshots
If applicable
```

## 💡 Suggesting Enhancements

### Enhancement Request Template

```markdown
## Feature Description
Clear description of the enhancement

## Motivation
Why this enhancement would be useful

## Proposed Solution
How you think this should be implemented

## Alternatives Considered
Other approaches you've thought about

## Additional Context
Any other relevant information
```

## 🤝 Code Review Process

1. **Automated checks** run on all PRs
2. **Maintainer review** - At least one maintainer must approve
3. **Address feedback** - Make requested changes
4. **Merge** - Maintainer will merge when approved

### Review Criteria

- Code quality and style
- Test coverage
- Documentation
- Performance impact
- Security considerations
- Backward compatibility

## 📞 Getting Help

- **Documentation**: Check existing docs first
- **Discussions**: Use GitHub Discussions for questions
- **Issues**: Create an issue for bugs or feature requests
- **Chat**: Join our community chat (if available)

## 🙏 Thank You!

Your contributions make OwlBoard better for everyone. We appreciate your time and effort!

## 📜 License

By contributing to OwlBoard, you agree that your contributions will be licensed under the same license as the project.
