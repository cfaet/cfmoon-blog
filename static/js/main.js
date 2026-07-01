document.addEventListener("DOMContentLoaded", () => {
	const navToggle = document.querySelector(".nav-toggle");
	const mainNav = document.querySelector(".main-nav");
	const themeToggle = document.querySelector(".theme-toggle");
	const themeQuery = window.matchMedia("(prefers-color-scheme: dark)");

	const getSavedTheme = () => {
		try {
			return localStorage.getItem("theme");
		} catch {
			return null;
		}
	};

	const saveTheme = (theme) => {
		try {
			localStorage.setItem("theme", theme);
		} catch {
			return;
		}
	};

	const getActiveTheme = () => {
		const savedTheme = getSavedTheme();
		if (savedTheme === "light" || savedTheme === "dark") {
			return savedTheme;
		}
		return themeQuery.matches ? "dark" : "light";
	};

	const setTheme = (theme, persist = true) => {
		document.documentElement.dataset.theme = theme;
		if (persist) {
			saveTheme(theme);
		}
		if (themeToggle) {
			themeToggle.setAttribute(
				"aria-label",
				theme === "dark" ? "Switch to light theme" : "Switch to dark theme",
			);
			themeToggle.setAttribute("aria-pressed", String(theme === "dark"));
		}
	};

	setTheme(getActiveTheme(), false);

	if (themeToggle) {
		themeToggle.addEventListener("click", () => {
			setTheme(getActiveTheme() === "dark" ? "light" : "dark");
		});
	}

	themeQuery.addEventListener("change", () => {
		if (!getSavedTheme()) {
			setTheme(getActiveTheme(), false);
		}
	});

	if (navToggle && mainNav) {
		navToggle.addEventListener("click", () => {
			const isOpen = mainNav.classList.toggle("is-open");
			navToggle.classList.toggle("is-active", isOpen);
			navToggle.setAttribute("aria-expanded", String(isOpen));
			navToggle.setAttribute("aria-label", isOpen ? "Close main menu" : "Open main menu");
		});
	}
});
