/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/design/adminhtml/**/*.phtml',
    './app/code/local/**/*.phtml',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Dark theme backgrounds (matching AI-LMS-TMS gray palette)
        'canvas': '#111827',
        'surface': {
          DEFAULT: '#1f2937',
          elevated: '#374151',
          hover: '#374151',
        },
        'on-surface': {
          DEFAULT: '#f9fafb',
          secondary: '#d1d5db',
          muted: '#9ca3af',
          faint: '#6b7280',
        },
        'border-default': '#374151',
        'primary': {
          DEFAULT: '#3b82f6',
          hover: '#2563eb',
          light: '#60a5fa',
        },
        'success': {
          DEFAULT: '#10b981',
          light: '#34d399',
        },
        'warning': {
          DEFAULT: '#f59e0b',
          light: '#fbbf24',
        },
        'error': {
          DEFAULT: '#ef4444',
          light: '#f87171',
        },
      },
    },
  },
  corePlugins: {
    preflight: false, // Don't reset Magento's existing styles
  },
}
