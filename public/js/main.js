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