const fs = require('fs');
const path = 'c:/flutter_dev/projects/bookies/packages/flutter_epub_viewer/lib/assets/webpage/html/epubView.js';
let content = fs.readFileSync(path, 'utf8');

const target = `function addUnderLine(cfiString, count) {
  try {
    var allContents = rendition.getContents();
    var annotation = null;
    var isParagraph = false;
    for (var i = 0; i < allContents.length; i++) {
      try {
        var range = allContents[i].range(cfiString);
        if (range) {
          var text = (range.toString() || '').trim();
          isParagraph = text.length > 150;
          if (isParagraph) {
            // Paragraph uses entirely DOM styling, no SVG fallback needed.
          } else {
            // Fallback SVG highlight (will be hidden by JS if DOM wrapping succeeds)
            annotation = rendition.annotations.highlight(
              cfiString, {}, function () {}, "discussion-phrase",
              { "fill": "#fd8a42", "fill-opacity": "0.15", "mix-blend-mode": "normal", "stroke": "none" }
            );
          }
          // Store meta and inject badge into this content frame
          _discussionMeta[cfiString] = { count: count, isParagraph: isParagraph };
          _injectBadgeForCfi(views[i].contents, cfiString, _discussionMeta[cfiString]);
          break;
        }
      } catch (e) {}
    }
    if (!annotation) {
      // Fallback: content not in current view, still store meta for later injection
      _discussionMeta[cfiString] = { count: count, isParagraph: false };
      rendition.annotations.highlight(cfiString, {}, function () {}, "discussion-phrase", {
        "fill": "#fd8a42", "fill-opacity": "0.15", "mix-blend-mode": "normal", "stroke": "none"
      });
    }
  } catch (e) {
    console.error("addUnderLine error", e);
  }
}`;

const replacement = `function addUnderLine(cfiString, count) {
  try {
    var allContents = rendition.getContents();
    var annotation = null;
    var isParagraph = false;
    for (var i = 0; i < allContents.length; i++) {
      try {
        var contents = allContents[i];
        
        // Prevent cross-chapter ghost highlights
        if (contents.window && contents.window.location && typeof book !== 'undefined' && book.spine) {
          var href = contents.window.location.href;
          var section = book.spine.spineItems.find(function(item) {
            return href.indexOf(item.href) !== -1 || href.indexOf(item.url) !== -1;
          });
          if (section && section.cfiBase) {
            var base = section.cfiBase.replace('epubcfi(', '').replace('!)', '!');
            if (cfiString.indexOf(base) === -1) continue;
          }
        }

        var range = contents.range(cfiString);
        if (range) {
          var text = (range.toString() || '').trim();
          isParagraph = text.length > 150;
          if (isParagraph) {
            // Paragraph uses entirely DOM styling, no SVG fallback needed.
          } else {
            // Fallback SVG highlight (will be hidden by JS if DOM wrapping succeeds)
            annotation = rendition.annotations.highlight(
              cfiString, {}, function () {}, "discussion-phrase",
              { "fill": "#fd8a42", "fill-opacity": "0.15", "mix-blend-mode": "normal", "stroke": "none" }
            );
          }
          // Store meta and inject badge into this content frame
          _discussionMeta[cfiString] = { count: count, isParagraph: isParagraph };
          _injectBadgeForCfi(contents, cfiString, _discussionMeta[cfiString]);
          break;
        }
      } catch (e) {}
    }
    if (!annotation && !isParagraph && !_discussionMeta[cfiString]) {
      // Fallback: content not in current view, still store meta for later injection
      _discussionMeta[cfiString] = { count: count, isParagraph: false };
      rendition.annotations.highlight(cfiString, {}, function () {}, "discussion-phrase", {
        "fill": "#fd8a42", "fill-opacity": "0.15", "mix-blend-mode": "normal", "stroke": "none"
      });
    }
  } catch (e) {
    console.error("addUnderLine error", e);
  }
}`;

if (content.includes(target)) {
  fs.writeFileSync(path, content.replace(target, replacement));
  console.log('Replaced successfully');
} else {
  console.log('Target not found');
}
