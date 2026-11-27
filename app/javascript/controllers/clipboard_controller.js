import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "buttonLabel"]
  static values = {
    successMessage: { type: String, default: "URLをコピーしました！🐾" }
  }

  async copy() {
    const text = this.sourceTarget.value

    try {
      await navigator.clipboard.writeText(text)
      this.showFeedback()
    } catch {
      // HTTP環境や一部ブラウザ向けのフォールバック
      this.sourceTarget.select()
      document.execCommand("copy")
      this.showFeedback()
    }
  }

  showFeedback() {
    const originalText = this.buttonLabelTarget.textContent
    this.buttonLabelTarget.textContent = this.successMessageValue

    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.buttonLabelTarget.textContent = originalText
    }, 2000)
  }
}