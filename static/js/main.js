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

	const copyText = async (text) => {
		if (navigator.clipboard && window.isSecureContext) {
			try {
				await navigator.clipboard.writeText(text);
				return;
			} catch {
				// Fall back to the selection API below.
			}
		}

		const textArea = document.createElement("textarea");
		textArea.value = text;
		textArea.setAttribute("readonly", "");
		textArea.style.position = "fixed";
		textArea.style.top = "-9999px";
		textArea.style.left = "-9999px";
		document.body.append(textArea);
		textArea.focus();
		textArea.select();

		try {
			if (!document.execCommand("copy")) {
				throw new Error("Copy command failed");
			}
		} finally {
			textArea.remove();
		}
	};

	document.querySelectorAll("div.sourceCode").forEach((block) => {
		if (block.dataset.copyReady === "true") {
			return;
		}

		const code = block.querySelector("code.sourceCode");
		if (!code) {
			return;
		}

		const button = document.createElement("button");
		button.className = "code-copy-button";
		button.type = "button";
		button.textContent = "Copy";
		button.setAttribute("aria-label", "Copy code");

		let resetTimer;
		const setButtonState = (state, label) => {
			clearTimeout(resetTimer);
			button.dataset.copyState = state;
			button.textContent = label;
			button.setAttribute("aria-label", label === "Copy" ? "Copy code" : label);
			resetTimer = window.setTimeout(() => {
				button.dataset.copyState = "idle";
				button.textContent = "Copy";
				button.setAttribute("aria-label", "Copy code");
			}, 1800);
		};

		button.addEventListener("click", async () => {
			const text = code.innerText.replace(/\u200b/g, "");

			try {
				await copyText(text);
				setButtonState("success", "Copied");
			} catch {
				setButtonState("error", "Copy failed");
			}
		});

		block.dataset.copyReady = "true";
		block.prepend(button);
	});
});
