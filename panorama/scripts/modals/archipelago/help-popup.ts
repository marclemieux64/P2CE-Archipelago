'use strict';

class HelpPopup {
	static currentPage = 1;

	static init() {
		this.currentPage = 1;
		this.updatePageVisibility();
	}

	static nextPage() {
		if (this.currentPage < 2) {
			this.currentPage++;
			this.updatePageVisibility();
		}
	}

	static prevPage() {
		if (this.currentPage > 1) {
			this.currentPage--;
			this.updatePageVisibility();
		}
	}

	static updatePageVisibility() {
		const root = $.GetContextPanel();
		if (!root) return;

		const page1 = root.FindChildTraverse('HelpPage1');
		const page2 = root.FindChildTraverse('HelpPage2');
		const prevBtn = root.FindChildTraverse('PrevPageButton');
		const nextBtn = root.FindChildTraverse('NextPageButton');
		const dot1 = root.FindChildTraverse('HelpDot1');
		const dot2 = root.FindChildTraverse('HelpDot2');
		const scroll = root.FindChildTraverse('HelpPopupScroll');

		if (scroll) {
			(scroll as any).ScrollToTop();
		}

		if (this.currentPage === 1) {
			page1?.RemoveClass('page-hidden');
			page2?.AddClass('page-hidden');
			if (prevBtn) {
				prevBtn.AddClass('disabled');
				prevBtn.hittest = false;
			}
			if (nextBtn) {
				nextBtn.RemoveClass('disabled');
				nextBtn.hittest = true;
			}
			dot1?.AddClass('active');
			dot2?.RemoveClass('active');
		} else {
			page1?.AddClass('page-hidden');
			page2?.RemoveClass('page-hidden');
			if (prevBtn) {
				prevBtn.RemoveClass('disabled');
				prevBtn.hittest = true;
			}
			if (nextBtn) {
				nextBtn.AddClass('disabled');
				nextBtn.hittest = false;
			}
			dot1?.RemoveClass('active');
			dot2?.AddClass('active');
		}
	}
}

