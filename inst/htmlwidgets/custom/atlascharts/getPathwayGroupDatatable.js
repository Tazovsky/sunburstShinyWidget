function columnPathBuilder (label, field, resolver) {
		return {
			title: label,
			data: (d) => resolver ? resolver(d.path[field]) : d.paths[field],
			defaultContent: ''
		};
	}

function columnValueBuilder (label, field, formatter, width) {
		return {
			title: label,
			data: (d) => formatter ? formatter(d[field]) : d[field] + "", // had to append '' because 0 value was not printing.
			defaultContent: '',
			width: width || '10%'
		};
	}

function percentFormat(v) {
		return `${v.toFixed(2)}%`;
	}



function unwrapPathwayGroup(pathwayGroup) {
				if (pathwayGroup) {
				return {
					// id: c.id,
					// name: c.name,
					targetCohortCount: pathwayGroup.targetCohortCount,
					totalPathwaysCount: pathwayGroup.totalPathwaysCount,
					pathways: pathwayGroup.pathways.map(p => ({ // split pathway paths into paths and counts
						path : p.path.split('-')
							.filter(step => step != "end") // remove end markers from pathway
							.map(p => +p)
							.concat(Array(MAX_PATH_LENGTH).fill(null)) // pad end of paths to be at least MAX_PATH_LENGTH
							.slice(0,MAX_PATH_LENGTH), // limit path to MAX_PATH_LENGTH.
						personCount: p.personCount
					}))
				}
			} else {
				return null;
			}
}

function getPathwayGroupData(pathwayGroup, pathLength) {
	let groups = pathwayGroup.pathways.reduce((acc,cur) => { // reduce pathways into a list of paths with counts
		const key = JSON.stringify(cur.path.slice(0,pathLength));
		if (!acc.has(key)) {
			acc.set(key, {personCount: cur.personCount, path: cur.path});
		} else {
			acc.get(key).personCount += cur.personCount;
		}
		return acc;
	}, new Map()).values();

	const data = Array.from(groups)
	data.forEach(row => { // add pathway and cohort percents
		row.pathwayPercent = 100.0 * row.personCount / pathwayGroup.pathwayCount;
		row.cohortPercent = 100.0 * row.personCount / pathwayGroup.cohortCount;
	});
	return data;
}


// works: getPathwayGroupDatatable(pathwayAnalysisDTO.pathwayGroups[0], 5)
// from:
/*
prepareReportData() {
			const design = this.results.design;
			const pathwayGroups = this.results.data.pathwayGroups;
			return({
				debugger;
				cohorts: design.targetCohorts.filter(c => this.filterList.selectedValues().includes(c.id)).map(c => {

					const pathwayGroup = pathwayGroups.find(p => p.targetCohortId == c.id);
*/

const MAX_PATH_LENGTH = 10;

function getPathwayGroupDatatable(pathwayGroup, pathLength) {
    //const MAX_PATH_LENGTH = 10;
    let pathCols = Array(MAX_PATH_LENGTH)
        .fill()
        .map((v, i) => {
            const colName = `Step ${i + 1}`; // Static string replacing ko.i18nformat
            const col = columnPathBuilder(colName, i, this.pathCodeResolver); // Removed ko.unwrap as well
            col.visible = i < pathLength;
            return col;
        });

    let statCols = [
        columnValueBuilder('Count', "personCount"), // Static string instead of ko.i18n
        columnValueBuilder('% with Pathway', "pathwayPercent", percentFormat), // Static string
        columnValueBuilder('% of Cohort', "cohortPercent", percentFormat) // Static string
    ];

    let unwrappedPathwayGroup = unwrapPathwayGroup(pathwayGroup);


    let data = unwrappedPathwayGroup ? this.getPathwayGroupData(unwrappedPathwayGroup, pathLength) : [];

	  //debugger;
    return {
        data: data,
        options: {
            order: [[pathCols.length, 'desc']],
            columnDefs: statCols.map((c, i) => ({ targets: pathCols.length + i, className: 'stat' })),
            columns: [...pathCols, ...statCols],
            language: { // Removed ko.i18n for language as well
                url: '' // You can specify a static or default language configuration here
            }
        }
    }
}


function prepareReportData(design, pathwayAnalysisDTO, targetCohortId) {
	//const design = design;
	const pathwayGroups = pathwayAnalysisDTO.pathwayGroups;
	return({
		cohorts: design.targetCohorts.filter(c => c.id == targetCohortId).map(c => {
			//debugger;
			const pathwayGroup = pathwayGroups.find(p => p.targetCohortId == c.id);
			if (pathwayGroup) {
				return {
					id: c.id,
					name: c.name,
					cohortCount: pathwayGroup.targetCohortCount,
					pathwayCount: pathwayGroup.totalPathwaysCount,
					pathways: pathwayGroup.pathways.map(p => ({ // split pathway paths into paths and counts
						path : p.path.split('-')
							.filter(step => step != "end") // remove end markers from pathway
							.map(p => +p)
							.concat(Array(MAX_PATH_LENGTH).fill(null)) // pad end of paths to be at least MAX_PATH_LENGTH
							.slice(0,MAX_PATH_LENGTH), // limit path to MAX_PATH_LENGTH.
						personCount: p.personCount
					}))
				}
			} else {
				return null;
			}
		}),
		//eventCodes: this.results.data.eventCodes
		eventCodes: null
	});
}
