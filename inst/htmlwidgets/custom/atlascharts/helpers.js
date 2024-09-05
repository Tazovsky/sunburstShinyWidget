function tooltipBuilder(d, data, colors_fun) {
  const nameBuilder = (name, color) => `<span class="tip-name" style="background-color:${color}; color: ${name == 'end' ? 'black' : 'white'}">${name}</span>`;
  const stepBuilder = (step) => `<div class="tip-step">${step.names.map(n => nameBuilder(n.name, n.color)).join("")}</div>`;

  //const path = this.getPathToNode(d);
  const path = getPathToNode2(d, data, colors_fun);
  //debugger;

  return `<div class="tip-container">${path.map(s => stepBuilder(s)).join("")}</div>`;
}

/*
function getPathToNode(node) {
	const eventCohorts = this.pathwaysObserver().eventCohorts;
	const colors = this.pathwaysObserver().colors; // charts.colors()
	let ancestors = this.getAncestors(node);
	let pathway = ancestors.map(p => (p.data.name == "end") ? {names: [{name: "end", color: colors("end")}], count: p.value} : {
		names: eventCohorts.filter(c => (c.code & Number.parseInt(p.data.name)) > 0)
						.map(ec => ({name: ec.name, color: colors(ec.code)})), count: p.value});
	return pathway;
}
*/

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
