import Alpine from "alpinejs";
import hljs from 'highlight.js'

window.Alpine = Alpine;

Alpine.start();

document.addEventListener('DOMContentLoaded', (event) => {
  hljs.highlightAll();
});
