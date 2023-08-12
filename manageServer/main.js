import { defineCustomElements } from './node_modules/@trimble-oss/modus-web-components/loader/index.js';

defineCustomElements();

const darkModeMatcher = window.matchMedia('(prefers-color-scheme: dark)');
const setDarkMode = (bool) => document.documentElement.setAttribute('data-mwc-theme', bool ? 'dark' : 'light');

if (darkModeMatcher.matches) setDarkMode(true);
darkModeMatcher.addEventListener('change', (event) => setDarkMode(event.matches));
