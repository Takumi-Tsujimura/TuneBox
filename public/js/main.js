document.addEventListener('DOMContentLoaded', () => {
  // ハンバーガーメニュー
  const menuButton = document.getElementById('menuButton');
  const menu = document.getElementById('menu');

  if (menuButton && menu) {
    menuButton.addEventListener('click', () => {
      menu.classList.toggle('open');
      document.body.classList.toggle('menu-open');
    });
  }

  // リンクをコピー
  const copyButtons = document.querySelectorAll('.copy-link');
  copyButtons.forEach(button => {
    button.addEventListener('click', () => {
      const link = button.getAttribute('data-link');
      navigator.clipboard.writeText(link)
        .then(() => {
          alert('リンクをコピーしました！');
        })
        .catch(err => {
          console.error('コピーに失敗しました:', err);
        });
    });
  });
});

// モーダルを開く関数
function openPopup(trackName, trackImage, trackArtists, trackId, formKey) {
  const modal = document.getElementById('modal');
  const trackInfo = document.getElementById('track-info');
  const formContent = document.getElementById('formContent');

  if (modal && trackInfo && formContent) {
    // モーダルを表示
    modal.style.display = 'block';

    // 曲情報をtrack-infoに表示（hiddenもここに埋め込む）
    trackInfo.innerHTML = `
      <h3>曲名: ${trackName}</h3>
      <input type="hidden" id="track_id" name="track_id" value="${trackId}">
      <input type="hidden" id="track_name" name="track_name" value="${trackName}">
      <input type="hidden" id="track_artists" name="track_artists" value="${trackArtists}">
      <p>アーティスト: ${trackArtists}</p>
      <img src="${trackImage}" alt="${trackName}" style="width: 100px; height: 100px;">
    `;

    // フォーム内容だけfetchしてformContentに埋め込む
    fetch(`/form/${formKey}/req_form`)
      .then(response => response.text())
      .then(html => {
        formContent.innerHTML = html;
      });
  }
}

// モーダルを閉じる関数
function closePopup() {
  const modal = document.getElementById('modal');
  if (modal) {
    modal.style.display = 'none';
  }
}
