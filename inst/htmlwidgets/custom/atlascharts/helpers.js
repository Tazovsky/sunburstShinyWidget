function tooltipBuilder(d, data, colors_fun) {

  const nameBuilder = (name, color) => `<span class="tip-name" style="background-color:${color}; color: ${name == 'end' ? 'black' : 'white'}">${name}</span>`;
  const stepBuilder = (step) => `<div class="tip-step">${step.names.map(n => nameBuilder(n.name, n.color)).join("")}</div>`;

  const path = getPathToNode2(d, data, colors_fun);

  var ttip = `<div class="tip-container">${path.map(s => stepBuilder(s)).join("")}</div>`;
  return ttip
}

function getAncestors(node) {
	var path = [];
	var current = node;
	while (current.parent) {
		path.unshift(current);
		current = current.parent;
	}
	return path;
}

function getPathToNode2(node, data, colors_fun) {
	//const eventCohorts = this.pathwaysObserver().eventCohorts;
	const eventCohorts = data.eventCohorts;
	//const colors = this.pathwaysObserver().colors; // charts.colors()
	const colors = colors_fun; // charts.colors()
	let ancestors = getAncestors(node);
	let pathway = ancestors.map(p => (p.data.name == "end") ? {names: [{name: "end", color: colors("end")}], count: p.value} : {
		names: eventCohorts.filter(c => (c.code & Number.parseInt(p.data.name)) > 0)
						.map(ec => ({name: ec.name, color: colors(ec.code)})), count: p.value});

	return pathway;
}


function click(d,i, data, colors_fun, elementId) {
          console.log(">>> click event -- i: " + i)
          console.log(">>> click event -- d: " + d)

          var sequenceArray = d.ancestors().reverse();
          sequenceArray.shift(); // remove root node from the array

          pathway = getPathToNode2(d, data, colors_fun);

          dispatch_.call("click", sequenceArray.map(
            function(d) {

              Shiny.setInputValue(
                elementId + "_click_data",
                {
                  d: d.data,
                  i: i,
                  data: data,
                  pathway: pathway
                },
                sequenceArray,
                {priority: "event"}
              );
              return d.data.name
            }
          ));
        }


class Helpers {
  constructor(d3) {
		this.d3 = d3
		this.dispatch_ = d3.dispatch("mouseover", "click");
  }

  getAncestors(node) {
		var path = [];
		var current = node;
		while (current.parent) {
			path.unshift(current);
			current = current.parent;
		}
		return path;
	};

	getPathToNode(node, data, colors_fun) {
		//const eventCohorts = this.pathwaysObserver().eventCohorts;
		const eventCohorts = data.eventCohorts;
		//const colors = this.pathwaysObserver().colors; // charts.colors()
		const colors = colors_fun; // charts.colors()
		let ancestors = this.getAncestors(node);
		let pathway = ancestors.map(p => (p.data.name == "end") ? {names: [{name: "end", color: colors("end")}], count: p.value} : {
			names: eventCohorts.filter(c => (c.code & Number.parseInt(p.data.name)) > 0)
							.map(ec => ({name: ec.name, color: colors(ec.code)})), count: p.value});

		return pathway;
	};

  click(d, i, data, colors_fun, elementId) {
      console.log(">>> click event -- i: " + i)
      console.log(">>> click event -- d: " + d)

      var sequenceArray = d.ancestors().reverse();
      sequenceArray.shift(); // remove root node from the array

      var pathway = this.getPathToNode(d, data, colors_fun);

      this.dispatch_.call("click", sequenceArray.map(
        function(d) {

          Shiny.setInputValue(
            elementId + "_click_data",
            {
              d: d.data,
              i: i,
              data: data,
              pathway: pathway
            },
            sequenceArray,
            {priority: "event"}
          );
          return d.data.name
        }
      ));
    }
}


  // Fade all but the current sequence, and show it in the breadcrumb trail.
  function mouseover(d) {
    console.log(">>> mouseover")

    debugger;

    var percentage = (100 * d.value / totalSize).toPrecision(3);
    var percentageString = percentage + "%";
    if (percentage < 0.1) {
      percentageString = "< 0.1%";
    }

    var countString = [
        '<span style = "font-size:.7em">',
        format("1.2s")(d.value) + ' of ' + format("1.2s")(totalSize),
        '</span>'
      ].join('')

    var explanationString = "";
    if(x.options.percent && x.options.count){
      explanationString = percentageString + '<br/>' + countString;
    } else if(x.options.percent){
      explanationString = percentageString;
    } else if(x.options.count){
      explanationString = countString;
    }

    //if explanation defined in R then use this instead
    if(x.options.explanation !== null){
      explanationString = x.options.explanation.bind(totalSize)(d);
    }


    select(el).selectAll(".sunburst-explanation")
        .style("visibility", "")
        .style("top",((height - 70)/2) + "px")
        .style("width",width + "px")
        .html(explanationString);

    var sequenceArray = d.ancestors().reverse();
    sequenceArray.shift(); // remove root node from the array

    chart._selection = sequenceArray.map(
      function(d){return d.data.name}
    );
    dispatch_.call("mouseover", chart._selection);

    updateBreadcrumbs(sequenceArray, percentageString);

    // Fade all the segments.
    select(el).selectAll("path")
        .style("opacity", 0.3);

    // Then highlight only those that are an ancestor of the current segment.
    vis.selectAll("path")
        .filter(function(node) {
                  return (sequenceArray.indexOf(node) >= 0);
                })
        .style("opacity", 1);
  }


