/* eslint-disable no-param-reassign */
/* global Breakpoints */

require('vendor/latinise');
require('./breakpoints');
require('vendor/jquery.nicescroll');

((global) => {
  const dasherize = str => str.replace(/[_\s]+/g, '-');
  const slugify = str => dasherize(str.trim().toLowerCase().latinise());

  class Wikis {
    constructor() {
      this.bp = Breakpoints.get();
      this.sidebarEl = document.querySelector('.js-wiki-sidebar');
      this.sidebarExpanded = false;
      $(this.sidebarEl).niceScroll();

      const sidebarToggles = document.querySelectorAll('.js-sidebar-wiki-toggle');
      for (let i = 0; i < sidebarToggles.length; i += 1) {
        sidebarToggles[i].addEventListener('click', e => this.handleToggleSidebar(e));
      }

      this.newWikiForm = document.querySelector('form.new-wiki-page');
      if (this.newWikiForm) {
        this.newWikiForm.addEventListener('submit', e => this.handleNewWikiSubmit(e));
      }

      window.addEventListener('resize', () => this.renderSidebar());
      this.renderSidebar();
    }

    handleNewWikiSubmit(e) {
      if (!this.newWikiForm) return;

      const slugInput = this.newWikiForm.querySelector('#new_wiki_path');
      const slug = slugify(slugInput.value);

      if (slug.length > 0) {
        const wikisPath = slugInput.getAttribute('data-wikis-path');
        window.location.href = `${wikisPath}/${slug}`;
        e.preventDefault();
      }
    }

    handleToggleSidebar(e) {
      e.preventDefault();
      this.sidebarExpanded = !this.sidebarExpanded;
      this.renderSidebar();
    }

    sidebarCanCollapse() {
      const bootstrapBreakpoint = this.bp.getBreakpointSize();
      return bootstrapBreakpoint === 'xs' || bootstrapBreakpoint === 'sm';
    }

    renderSidebar() {
      if (!this.sidebarEl) return;
      const { classList } = this.sidebarEl;
      if (this.sidebarExpanded || !this.sidebarCanCollapse()) {
        if (!classList.contains('right-sidebar-expanded')) {
          classList.remove('right-sidebar-collapsed');
          classList.add('right-sidebar-expanded');
        }
      } else if (classList.contains('right-sidebar-expanded')) {
        classList.add('right-sidebar-collapsed');
        classList.remove('right-sidebar-expanded');
      }
    }
  }

  global.Wikis = Wikis;
})(window.gl || (window.gl = {}));
