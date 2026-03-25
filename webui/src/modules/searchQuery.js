export function querySearchButtonShow(show) {
	const searchButtonForQuery = document.querySelector("#query-search");
	if (show) searchButtonForQuery.classList.remove("hidden");
	else searchButtonForQuery.classList.add("hidden");
}
