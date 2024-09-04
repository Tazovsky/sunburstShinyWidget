function utilModule(d3) {
  "use strict";

  var intFormat = d3.format(",.3r");

  function wrap(text, width) {
    text.each(function () {
      var text = d3.select(this),
        words = text.text().split(/\s+/).reverse(),
        word,
        line = [],
        lineNumber = 0,
        lineCount = 0,
        lineHeight = 1.1, // ems
        y = text.attr("y"),
        dy = parseFloat(text.attr("dy")),
        tspan = text.text(null).append("tspan").attr("x", 0).attr("y", y).attr("dy", dy + "em");
      while ((word = words.pop())) {
        line.push(word);
        tspan.text(line.join(" "));
        if (tspan.node().getComputedTextLength() > width) {
          if (line.length > 1) {
            line.pop(); // remove word from line
            words.push(word); // put the word back on the stack
            tspan.text(line.join(" "));
          }
          line = [];
          lineNumber += 1;
          tspan = text.append("tspan").attr("x", 0).attr("y", y).attr("dy", lineNumber * lineHeight + dy + "em");
        }
      }
    });
  }

  function formatInteger(d) {
    return intFormat(d);
  }

  function formatSI(p) {
    p = p || 0;
    return function (d) {
      if (d < 1) {
        return d3.round(d, p);
      }
      var prefix = d3.formatPrefix(d);
      return d3.round(prefix.scale(d), p) + prefix.symbol;
    };
  }

  function buildHierarchy(data, sequenceAccessor, sizeAccessor) {
    const seqAccessor = sequenceAccessor || (d => d[0]);
    const szAccessor = sizeAccessor || (d => d[1]);

    var root = {
      "name": "root",
      "children": []
    };
    for (var i = 0; i < data.length; i++) {
      var sequence = seqAccessor(data[i]);
      var size = +szAccessor(data[i]);
      if (isNaN(size)) { // e.g. if this is a header row, or the accessor did not return data
        continue;
      }
      var parts = sequence.split("-");
      var currentNode = root;
      for (var j = 0; j < parts.length; j++) {
        var children = currentNode["children"];
        var nodeName = parts[j];
        var childNode;
        if (j + 1 < parts.length) {
          var foundChild = false;
          for (var k = 0; k < children.length; k++) {
            if (children[k]["name"] == nodeName && children[k].children) {
              childNode = children[k];
              foundChild = true;
              break;
            }
          }
          if (!foundChild) {
            childNode = {
              "name": nodeName,
              "children": []
            };
            children.push(childNode);
          }
          currentNode = childNode;
        } else {
          childNode = {
            "name": nodeName,
            "size": size
          };
          children.push(childNode);
        }
      }
    }
    return root;
  }

  return {
    wrap: wrap,
    formatInteger: formatInteger,
    formatSI: formatSI,
    buildHierarchy: buildHierarchy
  };
}
