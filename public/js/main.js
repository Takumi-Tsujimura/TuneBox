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
  if (modal) {
    modal.style.display = 'block';
    document.getElementById('track-info').innerHTML = `
      <h3>曲名: ${trackName}</h3>
      <input id="track_id" name="track_id" value="${trackId}" type="hidden">
      <input id="track_name" name="track_name" value="${trackName}" type="hidden">
      <input id="track_artists" name="track_artists" value="${trackArtists}" type="hidden">
      <p>アーティスト: ${trackArtists}</p>
      <img src="${trackImage}" alt="${trackName}" style="width: 100px; height: 100px;">
    `;
    fetchForm(formKey); 
  }
}


// モーダルを閉じる関数
function closePopup() {
  const modal = document.getElementById('modal');
  if (modal) {
    modal.style.display = 'none';
  }
}

// フォーム内容を非同期で取得してモーダルに表示
function fetchForm(formKey) {
  fetch(`/form/${formKey}/req_form`)  // ← formKeyを使って正しいURLに！
    .then(response => response.text())
    .then(html => {
      const formContent = document.getElementById('formContent');
      if (formContent) {
        formContent.innerHTML = html;
      }
    });
}

