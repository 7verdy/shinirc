window.onload = function() {
    const messageInput = document.getElementById('message-input');
    const sendButton = document.getElementById('send-button');

    sendButton.onclick = function() {
        const message = messageInput.value;
        if (message) {
            messageInput.value = '';
        }
    }
};