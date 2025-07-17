# Contributing to Tumunu Live ISO

Thank you for your interest in contributing to the Tumunu Forensic Live ISO project! This document provides guidelines for contributing to ensure a consistent and high-quality codebase.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:
- Be respectful and inclusive
- Focus on constructive feedback
- Respect different viewpoints and experiences
- Prioritize security and forensic integrity
- Maintain professional communication

## Getting Started

### Development Environment Setup

1. **System Requirements**:
   - Ubuntu 20.04+ or Debian 11+
   - 8GB+ free disk space
   - Internet connectivity
   - Sudo privileges

2. **Clone and Setup**:
   ```bash
   git clone https://github.com/tumunu/tumunu-live-iso.git
   cd tumunu-live-iso
   make install-deps
   ```

3. **Validate Environment**:
   ```bash
   make validate
   ```

### Development Workflow

1. **Fork the Repository**
2. **Create Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make Changes**
4. **Test Changes**:
   ```bash
   make test
   make dev-build  # For quick testing
   ```
5. **Commit Changes**
6. **Push and Create Pull Request**

## Contribution Guidelines

### Security First

This is a forensic tool used in legal contexts. All contributions must:
- ✅ Pass security review
- ✅ Maintain evidence integrity
- ✅ Follow forensic best practices
- ✅ Not introduce security vulnerabilities
- ✅ Preserve chain of custody capabilities

### Code Quality Standards

#### Build System
- All builds must complete without warnings
- Use existing Make targets for consistency
- Test both development and production builds
- Validate against multiple hardware configurations

#### Shell Scripting
- Use `#!/bin/bash` for all shell scripts
- Include proper error handling with fallbacks
- Use consistent logging functions
- Test script syntax with `bash -n`
- Follow existing code style and patterns

#### Documentation
- Update README.md for user-facing changes
- Add inline comments for complex logic
- Update CHANGELOG.md for all changes
- Include examples for new features

### Plugin Development

#### Plugin Architecture
- Implement SecurityPlugin trait for integration
- Provide both .so binary and source builds
- Include comprehensive error handling
- Add plugin-specific documentation

#### Plugin Requirements
- Must not compromise forensic integrity
- Include proper error handling and logging
- Provide clear installation instructions
- Include test cases and validation

### Testing Requirements

#### Mandatory Tests
Before submitting any PR, ensure:
```bash
make test        # Full test suite
make test-vm     # Virtual machine boot test
make test-iso    # ISO structure validation
make test-plugins # Plugin integration test
```

#### Test Coverage
- Test both success and failure scenarios
- Validate error handling and recovery
- Test on different hardware configurations
- Include edge cases and boundary conditions

### Documentation Standards

#### User Documentation
- Clear, step-by-step instructions
- Include troubleshooting sections
- Provide examples and use cases
- Update for any user-facing changes

#### Technical Documentation
- Document architectural decisions
- Explain complex algorithms
- Include plugin integration guides
- Maintain API documentation

## Pull Request Process

### PR Requirements
1. **Description**: Clear description of changes and motivation
2. **Testing**: Evidence of thorough testing
3. **Documentation**: Updated documentation for changes
4. **Security**: Security impact assessment
5. **Backwards Compatibility**: Maintain compatibility where possible

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Build tests pass
- [ ] VM boot test passes
- [ ] Plugin integration tests pass
- [ ] Manual testing completed

## Security Review
- [ ] No sensitive information added
- [ ] Maintains forensic integrity
- [ ] No security vulnerabilities introduced
- [ ] Follows security best practices

## Documentation
- [ ] README updated
- [ ] CHANGELOG updated
- [ ] Code comments added
- [ ] API documentation updated
```

### Review Process
1. **Automated Checks**: CI/CD pipeline validation
2. **Security Review**: Security-focused code review
3. **Forensic Validation**: Forensic tool compliance check
4. **Manual Testing**: Real-world testing validation
5. **Documentation Review**: Documentation completeness check

## Specific Contribution Areas

### Build System Improvements
- Enhanced dependency management
- Build performance optimizations
- Additional platform support
- Improved error handling

### Plugin System Enhancements
- New plugin interfaces
- Plugin validation improvements
- Enhanced error handling
- Plugin documentation

### Security Enhancements
- Additional security features
- Vulnerability fixes
- Security audit improvements
- Compliance enhancements

### Documentation Improvements
- User guide enhancements
- Technical documentation
- Tutorial creation
- FAQ development

## Bug Reports

### Bug Report Template
```markdown
## Bug Description
Clear description of the issue

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., Ubuntu 22.04]
- Hardware: [e.g., Dell OptiPlex 7070]
- ISO Version: [e.g., 1.0.0]
- Build Date: [e.g., 2025-01-18]

## Logs
Include relevant log output
```

### Security Vulnerabilities
For security issues:
1. **DO NOT** create public issues
2. Email security@tumunu.com
3. Include detailed description
4. Provide reproduction steps
5. Suggest mitigation if known

## Feature Requests

### Feature Request Template
```markdown
## Feature Description
Clear description of the requested feature

## Use Case
Why is this feature needed?

## Proposed Implementation
How should this feature work?

## Security Considerations
Any security implications?

## Forensic Impact
How does this affect forensic procedures?
```

## Development Best Practices

### Code Style
- Follow existing code patterns
- Use meaningful variable names
- Include proper error handling
- Add comprehensive logging
- Test edge cases thoroughly

### Security Practices
- Validate all inputs
- Use secure communication (HTTPS)
- Implement proper authentication
- Follow least privilege principle
- Regular security audits

### Performance Considerations
- Optimize for forensic environments
- Consider memory constraints
- Test on various hardware
- Monitor resource usage
- Profile critical paths

## Resources

### Documentation
- [Project README](README.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Changelog](CHANGELOG.md)

### Tools
- [Debian Live Manual](https://live-team.pages.debian.net/live-manual/)
- [Syslinux Documentation](https://wiki.syslinux.org/)
- [Forensic Guidelines](https://www.nist.gov/digital-forensics)

### Community
- GitHub Discussions for questions
- GitHub Issues for bug reports
- Security email for vulnerabilities

---

## Recognition

Contributors who make significant contributions will be recognized in:
- Project documentation
- Release notes
- Contributor credits
- Community acknowledgments

Thank you for contributing to the Tumunu Forensic Live ISO project! Your contributions help improve digital forensic capabilities worldwide.

---

**Last Updated**: January 18, 2025  
**Version**: 1.0.0