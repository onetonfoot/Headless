const selectedElements = []

const selectedStyle = `
    .selected {
        background-color: blue;
        opacity: 0.5;
        border: solid black 1px;
    }
`
const hoverStyle = `
    .hover {
        background-color: yellow;
        opacity: 0.5;
        border: solid black 1px;
    }
`
function addStyle(css) {
    let styleTag = document.createElement('style');
    let dynamicStyleCss = document.createTextNode(css);
    styleTag.appendChild(dynamicStyleCss);
    let header = document.getElementsByTagName('head')[0];
    header.appendChild(styleTag);
};

addStyle(selectedStyle)
addStyle(hoverStyle)

container = document.querySelector("body")
container.onmouseover = container.onmouseout = handler

function handler(event) {

    let isSelected = selectedElements.some(element => {
        return element.isSameNode(event.target)
    })

    if (event.type == 'mouseover') {
        event.target.classList.add("hover")
    }

    if (event.type == 'mouseout') {
        event.target.classList.remove("hover")
    }
}

document.addEventListener("click", function (event) {
    console.log("Clicked element", event.srcElement)

    let isSelected = selectedElements.some(element => {
        return element.isSameNode(event.target)
    })

    if (!isSelected) {
        console.log("Adding style to element")
        event.target.classList.add("selected")
        selectedElements.push(event.target)
    } else {
        console.log("Removing style from element")
        event.target.classList.remove("selected")
        let idx = selectedElements.findIndex(element => {
            return element.isSameNode(event.target)
        })
        selectedElements.splice(idx, 1)
    }
})