import React from 'react'
import { createRoot } from 'react-dom/client'
import '@fontsource-variable/fraunces'
import '@fontsource-variable/dm-sans'
import '@fontsource-variable/manrope'
import './theme.css'

/*
  Default: full native-style ecommerce phone app.
  ?web=1: responsive desktop storefront companion.
  ?phone=1: explicit alias for the phone app.
*/
const root = createRoot(document.getElementById('root'))
const render = (Component) => root.render(
  <React.StrictMode>
    <Component />
  </React.StrictMode>
)

const params = new URLSearchParams(window.location.search)
if (params.has('web')) {
  Promise.all([
    import('./styles.css'),
    import('./App.jsx'),
  ]).then(([, module]) => render(module.default))
} else {
  import('./PhoneApp.jsx').then((module) => render(module.default))
}
