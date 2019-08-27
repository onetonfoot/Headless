let l = []

getEleAttributes = (ele) => {
    let result = ele.getAttributeNames()
        .map(x => [x, ele.getAttribute(x)]).reduce((obj, x) => {
            let [k, v] = x
            obj[k] = v
            return obj
        }, {})
    return result
}

document.addEventListener("click", function (event) {
    console.log("clicked element", event.srcElement)
    ele = event.srcElement
})


//Add overlay
document.addEventListener("dblclick", function (event) {
    path = event.path
        .filter(x => x instanceof HTMLElement)
        .map(x => getEleAttributes(x))
    l.push(path)
    console.log("dblclicked", path)
})


function _zip(func, args) {
    const iterators = args.map(arr => arr[Symbol.iterator]());
    let iterateInstances = iterators.map((i) => i.next());
    ret = []
    while (iterateInstances[func](it => !it.done)) {
        ret.push(iterateInstances.map(it => it.value));
        iterateInstances = iterators.map((i) => i.next());
    }
    return ret;
}

const zip = (...args) => _zip('every', args);


// zip(...l)

//Zip elements together and perform a sequence alignment of the html
