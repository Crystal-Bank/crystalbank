/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{svelte,js}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Outfit', "'Arial Black'", 'Helvetica', 'sans-serif'],
      },
      colors: {
        brand: {
          'deep-navy':    '#0D1B3E',
          'navy-mid':     '#122252',
          'crystal-ice':  '#7EEEFF',
          'crystal-glow': '#5DDDFF',
          'aqua-bright':  '#00C8F0',
          'crystal-blue': '#00B8E6',
          'ocean':        '#0088CC',
          'sapphire':     '#0066BB',
          'steel-blue':   '#005FA3',
          'abyss':        '#003A75',
          'indigo-deep':  '#004488',
          'off-white':    '#E8F4FF',
        },
      },
    },
  },
  plugins: [],
}
