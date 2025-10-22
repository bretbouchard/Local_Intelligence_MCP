// Local Intelligence MCP Landing Page JavaScript

// DOM Content Loaded
document.addEventListener('DOMContentLoaded', function() {
    // Initialize Lucide icons
    lucide.createIcons();

    initializeNavigation();
    initializeScrollEffects();
    initializeCopyButtons();
    initializeAnimations();
    initializeMobileMenu();
});

// Navigation functionality
function initializeNavigation() {
    const navbar = document.querySelector('.navbar');
    const navLinks = document.querySelectorAll('.nav-links a');

    // Smooth scrolling for navigation links
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            const href = this.getAttribute('href');

            if (href.startsWith('#')) {
                e.preventDefault();
                const target = document.querySelector(href);

                if (target) {
                    const offsetTop = target.offsetTop - 80; // Account for fixed navbar
                    window.scrollTo({
                        top: offsetTop,
                        behavior: 'smooth'
                    });

                    // Update active state
                    navLinks.forEach(navLink => navLink.classList.remove('active'));
                    this.classList.add('active');
                }
            }
        });
    });

    // Update active navigation on scroll
    window.addEventListener('scroll', function() {
        let current = '';
        const sections = document.querySelectorAll('section[id]');

        sections.forEach(section => {
            const sectionTop = section.offsetTop - 100;
            const sectionHeight = section.clientHeight;

            if (window.pageYOffset >= sectionTop &&
                window.pageYOffset < sectionTop + sectionHeight) {
                current = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${current}`) {
                link.classList.add('active');
            }
        });
    });
}

// Scroll effects
function initializeScrollEffects() {
    const navbar = document.querySelector('.navbar');
    let lastScrollTop = 0;

    window.addEventListener('scroll', function() {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

        // Navbar background opacity based on scroll
        if (scrollTop > 50) {
            navbar.style.background = 'rgba(255, 255, 255, 0.95)';
            navbar.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.1)';
        } else {
            navbar.style.background = 'rgba(255, 255, 255, 0.8)';
            navbar.style.boxShadow = 'none';
        }

        lastScrollTop = scrollTop;
    });
}

// Copy button functionality
function initializeCopyButtons() {
    const copyButtons = document.querySelectorAll('.copy-btn');

    copyButtons.forEach(button => {
        button.addEventListener('click', function() {
            const codeBlock = this.closest('.code-block');
            const code = codeBlock.querySelector('code').textContent;

            copyToClipboard(code).then(() => {
                // Show copied state
                const originalText = this.textContent;
                this.textContent = 'Copied!';
                this.classList.add('copied');

                // Reset after 2 seconds
                setTimeout(() => {
                    this.textContent = originalText;
                    this.classList.remove('copied');
                }, 2000);
            }).catch(err => {
                console.error('Failed to copy text: ', err);
            });
        });
    });
}

// Copy to clipboard function
async function copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
        return navigator.clipboard.writeText(text);
    } else {
        // Fallback for older browsers
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.left = '-999999px';
        textArea.style.top = '-999999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();

        try {
            document.execCommand('copy');
            textArea.remove();
            return Promise.resolve();
        } catch (err) {
            textArea.remove();
            return Promise.reject(err);
        }
    }
}

// Animation on scroll
function initializeAnimations() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');

                // Add staggered animation to grid items
                if (entry.target.classList.contains('features-grid') ||
                    entry.target.classList.contains('tools-categories') ||
                    entry.target.classList.contains('platforms-grid')) {

                    const items = entry.target.children;
                    Array.from(items).forEach((item, index) => {
                        setTimeout(() => {
                            item.classList.add('visible');
                        }, index * 100);
                    });
                }
            }
        });
    }, observerOptions);

    // Add fade-in classes to elements
    const animateElements = document.querySelectorAll(
        '.feature-card, .tool-category, .platform-card, .section-header, .hero-content, .hero-visual'
    );

    animateElements.forEach(el => {
        el.classList.add('fade-in-element');
        observer.observe(el);
    });

    // Animate hero content immediately
    const heroLeft = document.querySelector('.hero-left');
    const heroRight = document.querySelector('.hero-right');

    if (heroLeft) {
        setTimeout(() => {
            heroLeft.classList.add('visible');
        }, 100);
    }

    if (heroRight) {
        setTimeout(() => {
            heroRight.classList.add('visible');
        }, 300);
    }
}

// Mobile menu functionality
function initializeMobileMenu() {
    const menuToggle = document.getElementById('menuToggle');
    const navLinks = document.querySelector('.nav-links');
    let isMenuOpen = false;

    if (menuToggle) {
        menuToggle.addEventListener('click', function() {
            isMenuOpen = !isMenuOpen;

            if (isMenuOpen) {
                // Create mobile menu
                const mobileMenu = document.createElement('div');
                mobileMenu.className = 'mobile-menu';
                mobileMenu.innerHTML = `
                    <div class="mobile-menu-content">
                        <button class="mobile-menu-close" id="mobileMenuClose">×</button>
                        <div class="mobile-menu-links">
                            <a href="#features">Features</a>
                            <a href="#tools">Tools</a>
                            <a href="#installation">Installation</a>
                            <a href="#platforms">Platforms</a>
                            <a href="https://github.com/bretbouchard/Local_Intelligence_MCP" class="nav-github" target="_blank">GitHub</a>
                        </div>
                    </div>
                `;

                // Add styles for mobile menu
                const style = document.createElement('style');
                style.textContent = `
                    .mobile-menu {
                        position: fixed;
                        top: 0;
                        left: 0;
                        right: 0;
                        bottom: 0;
                        background: rgba(0, 0, 0, 0.5);
                        z-index: 10000;
                        display: flex;
                        align-items: flex-start;
                        justify-content: flex-end;
                        backdrop-filter: blur(10px);
                        -webkit-backdrop-filter: blur(10px);
                    }

                    .mobile-menu-content {
                        background: white;
                        width: 80%;
                        max-width: 300px;
                        height: 100vh;
                        padding: var(--spacing-lg);
                        position: relative;
                        box-shadow: -4px 0 20px rgba(0, 0, 0, 0.1);
                    }

                    .mobile-menu-close {
                        position: absolute;
                        top: var(--spacing-md);
                        right: var(--spacing-md);
                        background: none;
                        border: none;
                        font-size: 2rem;
                        cursor: pointer;
                        color: var(--apple-gray);
                        width: 40px;
                        height: 40px;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        border-radius: var(--radius-full);
                        transition: var(--transition-fast);
                    }

                    .mobile-menu-close:hover {
                        background: var(--apple-ultralight);
                        color: var(--apple-black);
                    }

                    .mobile-menu-links {
                        display: flex;
                        flex-direction: column;
                        gap: var(--spacing-lg);
                        margin-top: var(--spacing-xl);
                    }

                    .mobile-menu-links a {
                        text-decoration: none;
                        color: var(--apple-black);
                        font-weight: var(--font-weight-medium);
                        font-size: 1.125rem;
                        padding: var(--spacing-sm);
                        border-radius: var(--radius-sm);
                        transition: var(--transition-fast);
                    }

                    .mobile-menu-links a:hover {
                        background: var(--apple-ultralight);
                        color: var(--apple-blue);
                    }

                    .mobile-menu-links .nav-github {
                        background: var(--apple-black);
                        color: var(--apple-white);
                        text-align: center;
                        margin-top: var(--spacing-md);
                    }

                    .mobile-menu-links .nav-github:hover {
                        background: var(--apple-black-secondary);
                    }

                    @media (max-width: 768px) {
                        .mobile-menu-content {
                            width: 100%;
                            max-width: none;
                        }
                    }
                `;

                document.head.appendChild(style);
                document.body.appendChild(mobileMenu);

                // Animate menu in
                setTimeout(() => {
                    mobileMenu.style.opacity = '1';
                }, 10);

                // Close menu functionality
                const closeBtn = document.getElementById('mobileMenuClose');
                const mobileLinks = mobileMenu.querySelectorAll('.mobile-menu-links a');

                const closeMobileMenu = () => {
                    mobileMenu.style.opacity = '0';
                    setTimeout(() => {
                        document.body.removeChild(mobileMenu);
                        document.head.removeChild(style);
                        isMenuOpen = false;
                    }, 300);
                };

                closeBtn.addEventListener('click', closeMobileMenu);

                mobileLinks.forEach(link => {
                    link.addEventListener('click', () => {
                        closeMobileMenu();
                    });
                });

                // Close on background click
                mobileMenu.addEventListener('click', (e) => {
                    if (e.target === mobileMenu) {
                        closeMobileMenu();
                    }
                });
            }
        });
    }
}

// Utility functions
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Performance optimization
function initializePerformanceOptimizations() {
    // Lazy load images when needed
    const images = document.querySelectorAll('img[data-src]');
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.remove('lazy');
                imageObserver.unobserve(img);
            }
        });
    });

    images.forEach(img => imageObserver.observe(img));

    // Preload critical resources
    const criticalResources = [
        'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap'
    ];

    criticalResources.forEach(url => {
        const link = document.createElement('link');
        link.rel = 'preload';
        link.as = 'style';
        link.href = url;
        document.head.appendChild(link);
    });
}

// Error handling
window.addEventListener('error', function(e) {
    console.error('JavaScript error:', e.error);
});

// Analytics placeholder (can be replaced with actual analytics)
function trackEvent(eventName, properties = {}) {
    console.log('Track event:', eventName, properties);
    // Replace with actual analytics implementation
}

// Track page load
trackEvent('page_load', {
    page: window.location.pathname,
    referrer: document.referrer,
    timestamp: new Date().toISOString()
});

// Track button clicks
document.addEventListener('click', function(e) {
    if (e.target.classList.contains('btn')) {
        const buttonText = e.target.textContent.trim();
        trackEvent('button_click', {
            button: buttonText,
            url: e.target.href
        });
    }
});

// Initialize performance optimizations
initializePerformanceOptimizations();