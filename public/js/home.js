let form;

function handleFormInit() {
    form = this;
}

document.addEventListener("htmx:beforeRequest", function () {
    form.adding = true;
    document.querySelector("form .error-message").innerHTML = "";
});

document.addEventListener("htmx:afterRequest", function (e) {
    if (e.detail.successful) {
        const form = document.querySelector("#add-form");
        form.reset();
    }

    form.adding = false;
});

function formatCurrency(inputValue) {
    const numericValue = inputValue.replace(/\D/g, "");
    const decimalValue = Number(numericValue) / 100;
    return decimalValue.toFixed(2);
}

function handleInputChange(e) {
    const value = e.target.value;
    const numericValue = Number(value);
    if (isNaN(numericValue)) {
        return;
    }
    this.expenseValue = formatCurrency(value);
}

function handleEdit(e) {
    this.editing = true;

    requestAnimationFrame(() => {
        const listItem = e?.target.closest(".expense-list-item");
        const input = listItem?.querySelector('input[name="value"]');
        input?.focus();
    });
}

function handleDelete(e) {
    const listItem = e.target.closest(".expense-list-item");
    const dialog = listItem?.querySelector("dialog");
    dialog?.showModal();
}

function handleCancelDelete(e) {
    const listItem = e.target.closest(".expense-list-item");
    const dialog = listItem?.querySelector("dialog");
    dialog?.close();
}

window.handleFormInit = handleFormInit;
window.handleInputChange = handleInputChange;
window.formatCurrency = formatCurrency;
window.handleEdit = handleEdit;
window.handleDelete = handleDelete;
window.handleCancelDelete = handleCancelDelete;
