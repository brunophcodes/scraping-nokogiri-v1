module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme :{
    extend: {
      animation: {
        fade: 'fadeOut 5s ease-in-out forwards'
      },
      colors: {
        brown: {
          50: '#fdf8f6',
          100: '#f2e8e5',
          200: '#eaddd7',
          300: '#e0cec7',
          400: '#d2bab0',
          500: '#bfa094',
          600: '#a18072',
          700: '#977669',
          800: '#846358',
          900: '#43302b',
        },
      },
      safelist: [
        {
          pattern: /bg-(red|blue|yellow|purple|orange|gray|green|pink)-(500|600|700|800)/,
        }
      ],
      keyframes:  {
        fadeOut: {
          from: { opacity: 1 },
          to: { opacity: 0 },
        },
      },
    }
  }
}
