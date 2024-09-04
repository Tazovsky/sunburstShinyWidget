function ChartModule(d3, lodash, d3tip) {
  "use strict";

  class Chart {
    static get chartTypes() {
      return {
        AREA: 'AREA',
        BOXPLOT: 'BOXPLOT',
        DONUT: 'DONUT',
        HISTOGRAM: 'HISTOGRAM',
        LINE: 'LINE',
        TRELLISLINE: 'TRELLISLINE',
      };
    }

    render(data, target, w, h, chartOptions) {
      if (typeof target == "string") {
        target = document.querySelector(target);
      }

      this.cachedData = data;

      if (!this.doResize) {
        this.doResize = lodash.debounce(() => {
          this.render(this.cachedData, target, target.clientWidth, target.clientHeight, chartOptions);
        }, 250);
        window.addEventListener("resize", this.doResize);
      }
    }

    getOptions(chartSpecificDefaults, customOptions) {
      const options = Object.assign({}, {
        margins: {
          top: 10,
          right: 10,
          bottom: 10,
          left: 10,
        },
        xFormat: d3.format(',.0f'),
        yFormat: d3.format('s'),
        colors: d3.scaleOrdinal(d3.schemeCategory20.concat(d3.schemeCategory20c)),
      },
        Object.assign({}, chartSpecificDefaults),
        Object.assign({}, customOptions)
      );
      return options;
    }

    createSvg(target, width, height) {
      this.destroyTipIfExists();

      const container = d3.select(target);
      container.select('svg').remove();
      const chart = container.append('svg')
        .attr('preserveAspectRatio', 'xMinYMin meet')
        .attr('viewBox', `0 0 ${width} ${height}`)
        .append('g')
        .attr('class', 'chart');

      this.chart = chart;

      return chart;
    }

    useTip(tooltipConfigurer = () => { }, options) {
      this.destroyTipIfExists();

      this.tip = d3tip()
        .attr('class', 'd3-tip');

      tooltipConfigurer(this.tip, options);

      if (this.chart) {
        this.chart.call(this.tip);
      }

      return this.tip;
    }

    destroyTipIfExists() {
      if (this.tip) {
        this.tip.destroy();
      }
    }

    static normalizeDataframe(dataframe) {
      const keys = d3.keys(dataframe);
      const frame = Object.assign({}, dataframe);
      keys.forEach((key) => {
        if (!(dataframe[key] instanceof Array)) {
          frame[key] = [dataframe[key]];
        }
      });
      return frame;
    }

    static dataframeToArray(dataframe) {
      const keys = d3.keys(dataframe);
      let result;
      if (dataframe[keys[0]] instanceof Array) {
        result = dataframe[keys[0]].map((d, i) => {
          const item = {};
          keys.forEach(p => {
            item[p] = dataframe[p][i];
          });
          return item;
        });
      } else {
        result = [dataframe];
      }
      return result;
    }

    get formatters() {
      return {
        formatSI: (p) => {
          p = p || 0;
          const prefix = d3.format(`,.${p}s`);
          return (d) => {
            if (d < 1) {
              return d.toFixed(p).replace(/(\.0*|(?<=(\.[0-9]*))0*)$/, '');
            }
            return prefix(d).replace(/(\.0*|(?<=(\.[0-9]*))0*)$/, '');
          }
        },
      }
    }

    truncate(text, width) {
      text.each(function () {
        const t = d3.select(this);
        const originalText = t.text();
        let textLength = t.node().getComputedTextLength();
        let txt = t.text();
        while (textLength > width && txt.length > 0) {
          txt = txt.slice(0, -1);
          t.text(`${txt}...`);
          textLength = t.node().getComputedTextLength();
        }
        t.append('title').text(originalText);
      });
    }

    wrap(text, width, truncateAtLine) {
      text.each(function () {
        const txt = d3.select(this);
        const fullText = txt.text();
        const words = txt.text().split(/\s+/).reverse();
        let line = [];
        let word;
        let lineNumber = 0;
        let lineCount = 0;
        const lineHeight = 1.1; // ems
        const y = txt.attr('y');
        const dy = parseFloat(txt.attr('dy'));
        let tspan = txt
          .text(null)
          .append('tspan')
          .attr('x', 0)
          .attr('y', y)
          .attr('dy', `${dy}em`);
        while (word = words.pop()) {
          line.push(word);
          tspan.text(line.join(' '));
          if (tspan.node().getComputedTextLength() > width) {
            if (line.length > 1) {
              line.pop();
              words.push(word);
              const text = !!truncateAtLine && ++lineCount === truncateAtLine ? `${line.splice(0, line.length - 1).join(' ')}...` : line.join(' ');
              tspan.text(text);
            }
            line = [];
            tspan = txt
              .append('tspan')
              .attr('x', 0)
              .attr('y', y)
              .attr('dy', `${++lineNumber * lineHeight + dy}em`);
            if (!!truncateAtLine && truncateAtLine === lineCount) {
              tspan.remove();
              break;
            }
          }
        }
        txt.append('title').text(fullText);
      });
    }

    // Tooltips

    tooltipFactory(tooltips) {
      return (d) => {
        let tipText = '';

        if (tooltips !== undefined) {
          for (let i = 0; i < tooltips.length; i++) {
            let value = tooltips[i].accessor(d);
            if (tooltips[i].format !== undefined) {
              value = tooltips[i].format(value);
            }
            tipText += `${tooltips[i].label}: ${value}</br>`;
          }
        }

        return tipText;
      };
    }

    lineDefaultTooltip(xLabel, xFormat, xAccessor, yLabel, yFormat, yAccessor, seriesAccessor) {
      return (d) => {
        let tipText = '';
        if (seriesAccessor(d))
          tipText = `Series: ${seriesAccessor(d)}</br>`;
        tipText += `${xLabel}: ${xFormat(xAccessor(d))}</br>`;
        tipText += `${yLabel}: ${yFormat(yAccessor(d))}`;
        return tipText;
      }
    }

    donutDefaultTooltip(labelAccessor, valueAccessor, percentageAccessor) {
      return (d) =>
        `${labelAccessor(d)}: ${valueAccessor(d)} (${percentageAccessor(d)})`
    }

    static mapMonthYearDataToSeries(data, customOptions) {
      const defaults = {
        dateField: 'x',
        yValue: 'y',
        yPercent: 'p'
      };

      const options = Object.assign({}, defaults, customOptions);

      const series = {};
      series.name = 'All Time';
      series.values = [];
      data[options.dateField].map((datum, i) => {
        series.values.push({
          xValue: new Date(Math.floor(data[options.dateField][i] / 100), (data[options.dateField][i] % 100) - 1, 1),
          yValue: data[options.yValue][i],
          yPercent: data[options.yPercent][i]
        });
      });
      series.values.sort((a, b) => a.xValue - b.xValue);

      return [series];
    }

    static prepareData(rawData, chartType) {
      switch (chartType) {
        case this.chartTypes.BOXPLOT:
          if (!rawData.CATEGORY.length) {
            return null;
          }
          const data = rawData.CATEGORY.map((d, i) => ({
            Category: rawData.CATEGORY[i],
            min: rawData.MIN_VALUE[i],
            max: rawData.MAX_VALUE[i],
            median: rawData.MEDIAN_VALUE[i],
            LIF: rawData.P10_VALUE[i],
            q1: rawData.P25_VALUE[i],
            q3: rawData.P75_VALUE[i],
            UIF: rawData.P90_VALUE[i],
          }), rawData);
          const values = Object.values(data);
          const flattenData = values.reduce((accumulator, currentValue) =>
            accumulator.concat(currentValue), []
          );
          if (!flattenData.length) {
            return null;
          }
          return data;
      }
    }

    dispose() {
      this.destroyTipIfExists();
      if (this.doResize) {
        window.removeEventListener("resize", this.doResize);
      }
    }

  }

  return Chart;
}
