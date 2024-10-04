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

      keyframes:  {
        fadeOut: {
          from: { opacity: 1 },
          to: { opacity: 0 },
        },
      },
    }
  }
}
