document.querySelectorAll('a.smooth-scroll').forEach(link => {
    link.addEventListener('click', function(e) {
        const href = this.getAttribute('href');
        if (href && href.startsWith('#')) {
            e.preventDefault();
            document.querySelector(href).scrollIntoView({ behavior: 'smooth' });
            const menu = document.querySelector('.nav-links');
            if (menu.classList.contains('show')) {
                menu.classList.remove('show');
                const bars = document.querySelectorAll('.menu-toggle div');
                bars[0].style.transform = '';
                bars[1].style.opacity = '1';
                bars[2].style.transform = '';
            }
        }
    });
});

window.addEventListener('load', () => {
    const particlesConfig = {
        particles: {
            number: { value: window.innerWidth < 768 ? 30 : 50, density: { enable: true, value_area: 800 } },
            color: { value: '#ff6b6b' },
            shape: { type: 'circle', stroke: { width: 0, color: '#000000' } },
            opacity: { value: 0.5, random: true, anim: { enable: true, speed: 0.7, opacity_min: 0.1 } },
            size: { value: 3, random: true, anim: { enable: false } },
            line_linked: { enable: true, distance: 100, color: '#ff6b6b', opacity: 0.3, width: 1 },
            move: { enable: true, speed: 3, direction: 'none', random: true, straight: false, out_mode: 'out' }
        },
        interactivity: {
            detect_on: 'canvas',
            events: {
                onhover: { enable: window.innerWidth >= 768, mode: 'grab' },
                onclick: { enable: true, mode: 'push' },
                resize: true
            },
            modes: {
                grab: { distance: 150, line_linked: { opacity: 0.5 } },
                push: { particles_nb: 2 }
            }
        },
        retina_detect: true
    };

    particlesJS('particles-js', particlesConfig);

    const cards = document.querySelectorAll('.project-card, .dev-stats-card, .services-card, .about-content');
    cards.forEach((card, index) => {
        setTimeout(() => card.classList.add('visible'), index * 100);
    });

    document.getElementById('entryPrompt').style.display = 'flex';
});

const video = document.getElementById('backgroundVideo');
const servicesAudio = document.getElementById('servicesAudio');
const shutupServicesAudio = document.getElementById('shutupServicesAudio');
const aboutmeAudio = document.getElementById('aboutmeAudio');
const shutupAboutAudio = document.getElementById('shutupAboutAudio');
const achievementAudio = document.getElementById('achievementAudio');
const achievementNotification = document.getElementById('achievementNotification');
const entryPrompt = document.getElementById('entryPrompt');
const transitionGif = document.getElementById('transitionGif');
const transitionImg = transitionGif.querySelector('img');
const navLinks = document.querySelector('.nav-links');
const menuToggle = document.querySelector('.menu-toggle');

video.pause();
servicesAudio.pause();
shutupServicesAudio.pause();
aboutmeAudio.pause();
shutupAboutAudio.pause();
achievementAudio.pause();
video.muted = true;

document.querySelector('.content-overlay').style.display = 'none';
transitionGif.style.display = 'none';
achievementNotification.style.display = 'none';

function enterSite() {
    entryPrompt.style.display = 'none';
    transitionGif.style.display = 'block';
    transitionImg.src = '3.gif';
    document.querySelector('.content-overlay').style.display = 'block';
    video.play().catch(() => {});
    setTimeout(() => {
        transitionGif.classList.add('fade-out');
        setTimeout(() => {
            transitionGif.style.display = 'none';
            transitionGif.classList.remove('fade-out');
            transitionImg.src = '';
        }, 700);
    }, 700);
    setTimeout(showAchievement, 5000);
}

function showAchievement() {
    achievementNotification.style.display = 'flex';
    setTimeout(() => {
        achievementNotification.classList.add('visible');
        achievementAudio.play().catch(() => {});
    }, 100);
    setTimeout(() => {
        achievementNotification.classList.remove('visible');
        setTimeout(() => achievementNotification.style.display = 'none', 300);
    }, 5000);
}

function playServicesAudio() { aboutmeAudio.pause(); servicesAudio.currentTime = 0; servicesAudio.play().catch(() => {}); }
function playShutupServicesAudio() { servicesAudio.pause(); shutupServicesAudio.currentTime = 0; shutupServicesAudio.play().catch(() => {}); }
function playAboutmeAudio() { servicesAudio.pause(); aboutmeAudio.currentTime = 0; aboutmeAudio.play().catch(() => {}); }
function playShutupAboutAudio() { aboutmeAudio.pause(); shutupAboutAudio.currentTime = 0; shutupAboutAudio.play().catch(() => {}); }

menuToggle.addEventListener('click', () => {
    navLinks.classList.toggle('show');
    const bars = menuToggle.querySelectorAll('div');
    bars[0].style.transform = navLinks.classList.contains('show') ? 'rotate(45deg) translate(5px, 5px)' : '';
    bars[1].style.opacity = navLinks.classList.contains('show') ? '0' : '1';
    bars[2].style.transform = navLinks.classList.contains('show') ? 'rotate(-45deg) translate(5px, -5px)' : '';
});

const sections = document.querySelectorAll('.section');
const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) entry.target.classList.add('visible');
    });
}, { threshold: 0.1 });
sections.forEach(section => observer.observe(section));

let lastScrollTop = 0;
window.addEventListener('scroll', () => {
    const currentScroll = window.pageYOffset || document.documentElement.scrollTop;
    const nav = document.querySelector('nav');
    if (currentScroll > lastScrollTop && currentScroll > 100) {
        nav.classList.remove('visible');
        nav.classList.add('scrolled');
    } else {
        nav.classList.remove('scrolled');
        nav.classList.add('visible');
    }
    lastScrollTop = currentScroll <= 0 ? 0 : currentScroll;
}); 