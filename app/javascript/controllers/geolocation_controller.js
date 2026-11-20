import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status", "results", "button"]

  // 主要駅チップをタップした時に入力欄へセット
  selectStation(event) {
    const stationName = event.currentTarget.dataset.stationName
    if (!stationName) return

    this.inputTarget.value = stationName
    this.inputTarget.focus()
    this.showStatus(`「${stationName}」を出発地にセットしました！🐾`, false)
  }

  // 「いまいる場所から探す」ボタン押下時
  findNearestStations() {
    if (!navigator.geolocation) {
      this.showStatus("お使いのブラウザは位置情報に対応していません🐾", true)
      return
    }

    this.buttonTarget.disabled = true
    this.showStatus("現在地から近くの駅を探しています...🐾", false)
    this.resultsTarget.innerHTML = ""

    navigator.geolocation.getCurrentPosition(
      (position) => this.fetchStations(position.coords.latitude, position.coords.longitude),
      (error) => this.handleLocationError(error),
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 60000 }
    )
  }

  async fetchStations(lat, lng) {
    try {
      const response = await fetch(`/stations/nearest?lat=${lat}&lng=${lng}`, {
        headers: { "Accept": "application/json" }
      })
      const data = await response.json()

      if (!response.ok || data.error) {
        this.showStatus(data.error || "駅情報の取得に失敗しました🐾", true)
        return
      }

      const stations = data.stations || []
      if (stations.length === 0) {
        this.showStatus("周辺3km以内に駅が見つかりませんでした。手入力をお願いします🐾", true)
        return
      }

      this.renderStationButtons(stations)
      this.showStatus("近くの駅が見つかりました！タップして選んでください🐾", false)
    } catch (e) {
      this.showStatus("通信エラーが発生しました。もう一度お試しください🐾", true)
    } finally {
      this.buttonTarget.disabled = false
    }
  }

  renderStationButtons(stations) {
    this.resultsTarget.innerHTML = ""

    stations.forEach((st) => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.className =
        "w-full text-left bg-[#FFFDF9] hover:bg-[#FFF9EE] active:scale-[0.99] transition-all rounded-xl border-2 border-[#E59849] px-4 py-2.5 shadow-sm flex items-center justify-between"

      btn.innerHTML = `
        <div class="truncate pr-2">
          <span class="text-sm font-extrabold text-[#3D2B1F]">📍 ${this.escapeHtml(st.name)}</span>
        </div>
        <span class="text-xs font-bold text-[#C86D1F] bg-[#FDE6C4] px-2.5 py-0.5 rounded-full shrink-0">選択</span>
      `

      btn.addEventListener("click", () => {
        this.inputTarget.value = st.name
        this.inputTarget.focus()
        this.showStatus(`「${st.name}」を出発地にセットしました！🐾`, false)
      })

      this.resultsTarget.appendChild(btn)
    })
  }

  handleLocationError(error) {
    this.buttonTarget.disabled = false
    let message = "現在地を取得できませんでした🐾"
    if (error.code === error.PERMISSION_DENIED) {
      message = "位置情報の利用が許可されていません。ブラウザの設定を確認するか手入力してください🐾"
    } else if (error.code === error.TIMEOUT) {
      message = "位置情報の取得がタイムアウトしました。もう一度お試しください🐾"
    }
    this.showStatus(message, true)
  }

  showStatus(text, isError) {
    this.statusTarget.textContent = text
    this.statusTarget.classList.remove("hidden", "text-red-600", "text-[#6E543B]")
    this.statusTarget.classList.add(isError ? "text-red-600" : "text-[#6E543B]")
  }

  escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, (match) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    }[match]))
  }
}