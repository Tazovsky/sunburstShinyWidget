function resultDataConverterModule(d3, AtlasCharts) {

    class ResultDataConverter {

        constructor() {
            this.percentFormat = d3.format(".1%");
            this.numberFormat = d3.format(",");
        }

        convert(pathwayAnalysisDTO, design) {
            return this.prepareResultData(pathwayAnalysisDTO, design);
        }

        splitPathway(node) {
            if (isNaN(node.data.name)) {
                return [node];
            };

            let splitNodes = [...Number.parseInt(node.data.name).toString(2)].reverse().reduce((result, bit, i) => {
                if (bit == "1") {
                    let nodeClone = Object.assign({}, node);
                    nodeClone.data = { name: (1 << i).toString() };
                    result.push(nodeClone);
                }
                return result;
            }, [])

            const bandWidth = (node.y1 - node.y0) / splitNodes.length;

            return splitNodes.map((node, i) => {
                node.y0 = node.y0 + (i * bandWidth);
                node.y1 = node.y0 + bandWidth;
                return node;
            })
        }

        // get the sum of all size from hierarchy node
        sumChildren(node) {
            return node.children ? node.children.reduce((r, n) => r + this.sumChildren(n), 0) : node.size;
        }

        summarizeHierarchy(data) {
            return { totalPathways: this.sumChildren(data) };
        }

        getAncestors(node) {
            var path = [];
            var current = node;
            while (current.parent) {
                path.unshift(current);
                current = current.parent;
            }
            return path;
        }

        /*---------FUNCTIONS USED FOR TOOLTIP AND ONCLICK--------------------*/
        getPathToNode(node) {
            const eventCohorts = this.pathwaysObserver().eventCohorts;
            const colors = this.pathwaysObserver().colors;
            let ancestors = this.getAncestors(node);
            let pathway = ancestors.map(p => (p.data.name == "end") ? { names: [{ name: "end", color: colors("end") }], count: p.value } : {
                names: eventCohorts.filter(c => (c.code & Number.parseInt(p.data.name)) > 0)
                    .map(ec => ({ name: ec.name, color: colors(ec.code) })), count: p.value
            });
            return pathway;
        }

        tooltipBuilder(d) {
            const nameBuilder = (name, color) => `<span class="${this.classes('tip-name')}" style="background-color:${color}; color: ${name == 'end' ? 'black' : 'white'}">${name}</span>`;
            const stepBuilder = (step) => `<div class="${this.classes('tip-step')}">${step.names.map(n => nameBuilder(n.name, n.color)).join("")}</div>`;

            const path = this.getPathToNode(d);
            return `<div class="${this.classes('tip-container')}">${path.map(s => stepBuilder(s)).join("")}</div>`;
        }

        buildPathDetails(pathwayData, pathNode) { // USED ON CLICK
            let pathway = getPathToNode(pathNode);

            // { names: [], personCount, remainPct}
            const rowBuilder = (path, i, allPaths) => ({
                names: path.names,
                personCount: path.count,
                remainPct: path.count / pathwayData.summary.totalPathways
            });

            let rows = pathway.map(rowBuilder);
            rows.forEach((r, i) => {
                if (i > 0) {
                    r.diffPct = rows[i - 1].remainPct - r.remainPct;
                    r.diff = rows[i - 1].personCount - r.personCount;
                } else {
                    r.diffPct = 1.0 - r.remainPct;
                    r.diff = pathwayData.summary.totalPathways - r.personCount;
                }
            });

            return { tableData: rows };
        }

        /*--------- END FUNCTIONS USED FOR TOOLTIP AND ONCLICK--------------------*/


        getFilterList(design) {
            const cohorts = design.targetCohorts.map(c => ({ label: c.name, value: c.id }));

            return [
                {
                    type: 'multiselect',
                    label: 'Cohorts',
                    name: 'cohorts',
                    options: cohorts,
                    selectedValues: cohorts.map(c => c.value),
                }
            ];
        }

        formatDate(date) {
            return momentAPI.formatDateTimeUTC(date);
        }


        formatNumber(value) {
            return this.numberFormat(value);
        }

        formatPct(value) {
            return this.percentFormat(value);
        }

        formatDetailValue(value, percent) {
            return this.formatNumber(value) + ' (' + this.formatPct(percent) + ')';
        }

        buildHierarchy(data) {
            return AtlasCharts.util
                .buildHierarchy(data,
                    d => d.path,
                    d => d.personCount
                );
        }

        getSelectedFilterValues = (filterList) => filterList.reduce(
            (selectedAgg, filterEntry) => {

                if (filterEntry.type === 'select') {
                    selectedAgg[filterEntry.name] = filterEntry.selectedValue;
                }
                else if (filterEntry.type === 'multiselect') {
                    selectedAgg[filterEntry.name] = filterEntry.selectedValues;
                }

                return selectedAgg;
            },
            {}
        );


        prepareResultData(results, design) {

            results.pathwayGroups.forEach(pg => {
                pg.pathways.forEach(pw => {
                    if (pw.path.split("-").length < design.maxDepth)   // design is feched in atlas via: PathwayService.loadExportDesignByGeneration(this.executionId())
                        pw.path = pw.path + "-end";
                });
            });

            const filterList = this.getFilterList(design);

            const selectedCohortIds = this.getSelectedFilterValues(filterList).cohorts;

            if (!results || selectedCohortIds == undefined || selectedCohortIds.length == 0) return null;


            const cohortPathways = selectedCohortIds.map(id => {
                let result = null;
                const pathwayGroup = results.pathwayGroups.find(g => id == g.targetCohortId);
                if (pathwayGroup) {
                    const pathway = this.buildHierarchy(pathwayGroup.pathways);
                    const targetCohort = design.targetCohorts.find(c => id == c.id);
                    const summary = { ...this.summarizeHierarchy(pathway), cohortPersons: pathwayGroup.targetCohortCount, pathwayPersons: pathwayGroup.totalPathwaysCount };
                    result = {
                        pathway,
                        targetCohortName: targetCohort.name,
                        targetCohortCount: this.formatNumber(summary.cohortPersons),
                        personsReported: this.formatNumber(summary.pathwayPersons),
                        personsReportedPct: this.formatPct(summary.pathwayPersons / summary.cohortPersons),
                        summary
                    };
                }
                return result;
            }).filter(cp => cp);

            const eventCohorts = results.eventCodes.filter(ec => !ec.isCombo)
            const colorScheme = d3.scaleOrdinal(eventCohorts.length > 10 ? d3.schemeCategory20 : d3.schemeCategory10);
            // initialize colors based on design
            design.eventCohorts.forEach((d, i) => colorScheme(Math.pow(2, i)));
            const fixedColors = { "end": "rgba(185, 184, 184, 0.23)" };
            const colors = (d) => (fixedColors[d] || colorScheme(d));


            return {
                eventCodes: results.eventCodes,
                cohortPathways: cohortPathways,
                colors: colors,
                title: design.name,
                eventCohorts: eventCohorts
            };

        }


        loadData() {
            this.loading(true);

            Promise.all([
                SourceService.loadSourceList(),
                PathwayService.loadExportDesignByGeneration(this.executionId()),
                PathwayService.getExecution(this.executionId()),
                PathwayService.getResults(this.executionId())
            ]).then(([
                sourceList,
                design,
                execution,
                executionResults
            ]) => {
                const source = sourceList.find(s => s.sourceKey === execution.sourceKey);

                executionResults.pathwayGroups.forEach(pg => {
                    pg.pathways.forEach(pw => {
                        if (pw.path.split("-").length < design.maxDepth)
                            pw.path = pw.path + "-end";
                    });
                });

                const results = {
                    executionId: this.executionId(),
                    sourceId: source.sourceId,
                    sourceName: source.sourceName,
                    date: execution.endTime,
                    design: design,
                    designHash: execution.hashCode,
                    data: executionResults
                };
                this.results(results);

                this.filterList(this.getFilterList(design));

                this.loading(false);
            });
        }
    }
    return ResultDataConverter;

}

