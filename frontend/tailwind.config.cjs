/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      backgroundSize: {
        'size-100': '100% 100%',
        'size-110': '125% 125%',
        'size-200': '200% 200%',
      },
    },
  },
  plugins: [require('@tailwindcss/typography')],
}
