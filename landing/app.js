// ==========================================================================
// Sha Collects — Interactive Landing Page Logic
// Features: Dynamic ROI Calculator, Download Notifications, Smooth Scroll
// ==========================================================================

document.addEventListener('DOMContentLoaded', () => {
  // Mobile Navigation Toggle
  const mobileToggle = document.getElementById('mobile-toggle-btn');
  const navMenu = document.getElementById('nav-menu');

  if (mobileToggle && navMenu) {
    mobileToggle.addEventListener('click', () => {
      const isVisible = navMenu.style.display === 'flex';
      navMenu.style.display = isVisible ? 'none' : 'flex';
      navMenu.style.flexDirection = 'column';
      navMenu.style.position = 'absolute';
      navMenu.style.top = '100%';
      navMenu.style.left = '0';
      navMenu.style.right = '0';
      navMenu.style.background = 'rgba(7, 11, 19, 0.95)';
      navMenu.style.padding = '1.5rem';
      navMenu.style.borderBottom = '1px solid rgba(255, 255, 255, 0.1)';
      navMenu.style.backdropFilter = 'blur(16px)';
    });
  }

  // Currency Formatter Utility
  function formatINR(number) {
    return '₹ ' + Number(number).toLocaleString('en-IN');
  }

  // Interactive ROI & Field Collection Calculator
  const agentsSlider = document.getElementById('agents-slider');
  const shopsSlider = document.getElementById('shops-slider');
  const avgCollSlider = document.getElementById('avg-coll-slider');

  const agentsVal = document.getElementById('agents-val');
  const shopsVal = document.getElementById('shops-val');
  const avgCollVal = document.getElementById('avg-coll-val');

  const resultMonthlyCash = document.getElementById('result-monthly-cash');
  const resultHoursSaved = document.getElementById('result-hours-saved');

  function updateCalculator() {
    if (!agentsSlider || !shopsSlider || !avgCollSlider) return;

    const agents = parseInt(agentsSlider.value, 10);
    const shopsPerDay = parseInt(shopsSlider.value, 10);
    const avgCollection = parseInt(avgCollSlider.value, 10);

    // Update Label Badges
    agentsVal.textContent = `${agents} Agent${agents > 1 ? 's' : ''}`;
    shopsVal.textContent = `${shopsPerDay} Shops`;
    avgCollVal.textContent = formatINR(avgCollection);

    // 26 working collection days per month
    const workingDays = 26;
    const totalDailyCollections = agents * shopsPerDay * avgCollection;
    const monthlyTotal = totalDailyCollections * workingDays;

    // Approximate 30 minutes saved per agent per day on physical receipts & manual bookkeeping
    const hoursSavedPerMonth = Math.round(agents * 0.5 * workingDays);

    // Update Result Elements
    resultMonthlyCash.textContent = formatINR(monthlyTotal);
    resultHoursSaved.textContent = `${hoursSavedPerMonth} hrs`;
  }

  if (agentsSlider && shopsSlider && avgCollSlider) {
    agentsSlider.addEventListener('input', updateCalculator);
    shopsSlider.addEventListener('input', updateCalculator);
    avgCollSlider.addEventListener('input', updateCalculator);
    updateCalculator(); // Initialize on load
  }

  // Download Trigger Feedback Notification
  const downloadTriggers = document.querySelectorAll('.download-trigger, #main-download-apk-btn, #nav-download-btn, #deepdive-download-btn');

  function showDownloadToast() {
    // Check if toast already exists
    let toast = document.getElementById('download-toast');
    if (!toast) {
      toast = document.createElement('div');
      toast.id = 'download-toast';
      toast.style.position = 'fixed';
      toast.style.bottom = '2rem';
      toast.style.right = '2rem';
      toast.style.background = 'rgba(13, 21, 36, 0.95)';
      toast.style.border = '1px solid rgba(16, 185, 129, 0.4)';
      toast.style.borderRadius = '14px';
      toast.style.padding = '1rem 1.4rem';
      toast.style.color = '#FFFFFF';
      toast.style.boxShadow = '0 20px 40px rgba(0, 0, 0, 0.6), 0 0 20px rgba(16, 185, 129, 0.2)';
      toast.style.zIndex = '9999';
      toast.style.display = 'flex';
      toast.style.alignItems = 'center';
      toast.style.gap = '0.9rem';
      toast.style.backdropFilter = 'blur(16px)';
      toast.style.transition = 'all 0.3s ease';
      document.body.appendChild(toast);
    }

    toast.innerHTML = `
      <div style="width: 38px; height: 38px; border-radius: 50%; background: #10B981; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 1.1rem; flex-shrink: 0;">
        <i class="fa-solid fa-arrow-down"></i>
      </div>
      <div>
        <div style="font-weight: 700; font-size: 0.95rem;">Downloading Sha_Collects.apk</div>
        <div style="font-size: 0.8rem; color: #94A3B8;">Check your notification bar or downloads folder (58.8 MB)</div>
      </div>
    `;

    toast.style.opacity = '1';
    toast.style.transform = 'translateY(0)';

    setTimeout(() => {
      if (toast) {
        toast.style.opacity = '0';
        toast.style.transform = 'translateY(20px)';
      }
    }, 4500);
  }

  downloadTriggers.forEach(btn => {
    btn.addEventListener('click', () => {
      showDownloadToast();
    });
  });

  // Smooth Active Nav Link Highlighting on Scroll
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-link');

  window.addEventListener('scroll', () => {
    let current = '';
    const scrollY = window.pageYOffset;

    sections.forEach(section => {
      const sectionHeight = section.offsetHeight;
      const sectionTop = section.offsetTop - 120;
      if (scrollY > sectionTop && scrollY <= sectionTop + sectionHeight) {
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
});
