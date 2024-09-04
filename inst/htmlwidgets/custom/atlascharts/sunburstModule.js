function SunburstModule(d3, Chart) {
  "use strict";

  class Sunburst extends Chart {

    getTipDirection(d) {
      return "n";
    }

    getTipOffset(d, arc) {
      const bbox = event.target.getBBox();
      const arcCenter = arc.centroid(d);
      let tipOffsetX = Math.abs(bbox.x - arcCenter[0]) - (bbox.width / 2);
      let tipOffsetY = Math.abs(bbox.y - arcCenter[1]);
      return [tipOffsetY - 10, tipOffsetX];
    }

    render(data, target, width, height, chartOptions) {
      super.render(data, target, width, height, chartOptions);

      const defaultOptions = {
        tooltip: (d) => {
          return `<div>No Tooltip Set</div>`;
        },
        minRadians: 0.005
      };

      const options = this.getOptions(defaultOptions, chartOptions);

      const svg = this.createSvg(target, width, height);
      svg.attr('class', 'sunburst');

      this.useTip((tip, options) => {
        tip.attr('class', `d3-tip ${options.tipClass || ""}`)
          .offset(d => d.tipOffset || [-10, 0])
          .direction(d => d.tipDirection || "n")
          .html(d => options.tooltip(d));
      }, options);

      const vis = svg.append("svg:g")
        .attr("transform", `translate(${width / 2}, ${height / 2})`);

      const radius = Math.min(width, height) / 2;

      const partition = d3.partition()
        .size([2 * Math.PI, radius]);

      const arc = d3.arc()
        .startAngle(d => d.x0)
        .endAngle(d => d.x1)
        .innerRadius(d => d.y0)
        .outerRadius(d => d.y1);

      vis.append("svg:circle")
        .attr("r", radius)
        .style("opacity", 0);

      const root = d3.hierarchy(data)
        .sum(d => d.size)
        .sort((a, b) => b.value - a.value);

      let nodes = partition(root).descendants().filter(d => (d.x1 - d.x0 > options.minRadians)).reverse();

      if (options.split) {
        const multiNodes = nodes.reduce((result, node) => {
          let splitNodes = options.split(node);
          if (splitNodes.length > 1) {
            node.isSplit = true;
            result = result.concat(splitNodes.map(n => Object.assign(n, {
              isPartialNode: true
            })));
          }
          return result;
        }, []);

        vis.data([data]).selectAll("partialnode")
          .data(multiNodes)
          .enter()
          .append("svg:path")
          .attr("d", arc)
          .attr("fill-rule", "evenodd")
          .attr("class", "partial")
          .style("fill", d => options.colors(d.data.name));
      }

      const self = this;

      vis.data([data]).selectAll("pathnode")
        .data(nodes)
        .enter()
        .append("svg:path")
        .attr("display", d => d.depth ? null : "none")
        .attr("d", arc)
        .attr("fill-rule", "evenodd")
        .attr("class", d => (options.nodeClass && options.nodeClass(d)) || "node")
        .style("fill", d => d.isSplit ? "#000" : options.colors(d.data.name))
        .style("opacity", d => d.isSplit ? 0 : 1)
        .on('mouseover', d => self.tip.show(Object.assign({}, d, { tipDirection: self.getTipDirection(d), tipOffset: self.getTipOffset(d, arc) }), event.target))
        .on('mouseout', d => self.tip.hide(d, event.target))
        .on('click', (d, i)=> options.onclick && options.onclick(d, i, data));
    }
  }

  return Sunburst;
}
