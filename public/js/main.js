// モーダルを開く関数
function openPopup(trackName, trackImage, trackArtists, trackId) {
    document.getElementById('modal').style.display = 'block';
    document.getElementById('track-info').innerHTML = `
        <h3>曲名: ${trackName}</h3>
        <input id="track_id" name="track_id" value="${trackId}" type="hidden">
        <input id="track_name" name="track_name" value="${trackName}" type="hidden">
        <input id="track_artists" name="track_artists" value="${trackArtists}" type="hidden">
        <p>アーティスト: ${trackArtists}</p>
        <img src="${trackImage}" alt="${trackName}" style="width: 100px; height: 100px;">
      `;
      fetchForm(); // フォームの内容を取得して表示
}

// モーダルを閉じる関数
function closePopup() {
    document.getElementById('modal').style.display = 'none';
}

// 非同期でフォームを取得してモーダル内に表示
function fetchForm() {
    fetch('/req_form')
        .then(response => response.text())
        .then(html => {
           document.getElementById('formContent').innerHTML = html;
        });
}

const menuButton = document.getElementById('menuButton');
  const menu = document.getElementById('menu');
  
  menuButton.addEventListener('click', () => {
    menu.classList.toggle('open');
    document.body.classList.toggle('menu-open'); // bodyにクラスを付け外
});

document.addEventListener('DOMContentLoaded', () => {
  const menuButton = document.getElementById('menuButton');
  const menu = document.getElementById('menu');
  
  menuButton.addEventListener('click', () => {
    menu.classList.toggle('open');
    document.body.classList.toggle('menu-open');
  });

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