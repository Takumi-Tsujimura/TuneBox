document.addEventListener('DOMContentLoaded', () => {
  setupMenuToggle();
  setupCopyLinks();
});

// ===== ハンバーガーメニュー =====
function setupMenuToggle() {
  const menuButton = document.getElementById('menuButton');
  const menu = document.getElementById('menu');

  if (menuButton && menu) {
    menuButton.addEventListener('click', () => {
      menu.classList.toggle('open');
      document.body.classList.toggle('menu-open');
    });
  }
}

// ===== リンクコピー機能 =====
function setupCopyLinks() {
  const copyButtons = document.querySelectorAll('.copy-link');
  copyButtons.forEach(button => {
    button.addEventListener('click', () => {
      const link = button.getAttribute('data-link');
      if (link) {
        navigator.clipboard.writeText(link)
          .then(() => {
            alert('リンクをコピーしました！');
          })
          .catch(err => {
            console.error('コピーに失敗しました:', err);
          });
      }
    });
  });
}

// ===== モーダル操作共通関数 =====
function openModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.style.display = 'block';
  }
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.style.display = 'none';
  }
}

// ===== 曲リクエスト用ポップアップ =====
function openPopup(button) {
  const { name: trackName, image: trackImage, artists: trackArtists, id: trackId, formKey } = button.dataset;
  const modal = document.getElementById('modal');
  const trackInfo = document.getElementById('track-info');
  const formContent = document.getElementById('formContent');

  if (modal && trackInfo && formContent) {
    openModal('modal');

    trackInfo.innerHTML = `
      <div class="d-flex flex-column align-items-start">
        <img src="${trackImage}" alt="${trackName}" class="img-thumbnail mb-3" style="width: 200px; height: 200px;">
        <h5 class="mb-1">曲名: ${trackName}</h5>
        <p class="mb-1">アーティスト: ${trackArtists}</p>
        <input type="hidden" id="track_id" name="track_id" value="${trackId}">
        <input type="hidden" id="track_name" name="track_name" value="${trackName}">
        <input type="hidden" id="track_artists" name="track_artists" value="${trackArtists}">
      </div>
    `;

    fetch(`/form/${formKey}/req_form`)
      .then(response => response.text())
      .then(html => {
        formContent.innerHTML = html;
      })
      .catch(error => {
        console.error('フォームの読み込みに失敗しました:', error);
      });
  }
}

function closePopup() {
  closeModal('modal');
}

// ===== フォーム共有用モーダル =====
function openShareModal(formKey) {
  openModal('shareModal');

  fetch(`/share?form_key=${formKey}`)
    .then(response => response.text())
    .then(html => {
      document.getElementById('shareModalContent').innerHTML = html;
      setupCopyLinks();  // ←ここ追加！！ モーダルを開いたあとにもイベントを付け直す
    })
    .catch(error => {
      console.error('エラー:', error);
    });
}

function closeShareModal() {
  closeModal('shareModal');
}

// ===== プレイリストモーダルを開く =====
function openPlaylistModal() {
  fetch('/add_playlist_form')
    .then(response => {
      if (!response.ok) {
        throw new Error('ネットワークエラー');
      }
      return response.text();
    })
    .then(html => {
      const playlistModalContent = document.getElementById('playlistModalContent');
      if (playlistModalContent) {
        playlistModalContent.innerHTML = html;
      } else {
        console.error('playlistModalContentが見つからない');
      }
      openModal('playlistModal');
    })
    .catch(error => {
      console.error('フォームの読み込みに失敗しました:', error);
    });
}
