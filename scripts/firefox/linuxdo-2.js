// ==UserScript==
// @name        linux.do badges recover post link
// @namespace   Violentmonkey Scripts
// @version     1.0.0
// @match       https://linux.do/badges/*/-?username=*
// @author      -
// @description
// @run-at      document-start
// @grant       none
// @allFrames   true
// ==/UserScript==
var xhrOpen = XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.open = function (m, url) {
  if (url && url.startsWith('/user_badges.json')) {
    this.addEventListener('load', function() {
      const xhr = this;
      const resp = JSON.parse(xhr.responseText || '{}');
      const badges = resp?.user_badge_info?.user_badges;
      const topics = resp?.topics;
      setTimeout(() => {
        const links = document.querySelectorAll('div.user-info > div.user-detail a.post-link');
        for (let i = 0; i < links.length; i++) {
          if (!links[i]?.innerText?.trim()) {
            const b = badges[i];
            const href = '/t/topic/' + b.topic_id + '/' + b.post_number;
            const name = topics.find(t => t.id === b.topic_id)?.fancy_title;
            links[i].innerText = name;
            links[i].href = href;
          }
        }
      }, 1234)
    })
  }
  return xhrOpen.apply(this, arguments)
}
