(() => {
  const form = document.querySelector('#supportForm');
  if (!form) return;

  const button = form.querySelector('button[type="submit"]');
  const status = document.querySelector('#formStatus');

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    status.className = 'form-status';
    status.textContent = '';
    button.disabled = true;
    button.textContent = '正在提交';

    const data = new FormData(form);
    const payload = Object.fromEntries(data.entries());
    Object.keys(payload).forEach((key) => {
      if (typeof payload[key] === 'string') payload[key] = payload[key].trim();
      if (!payload[key]) delete payload[key];
    });

    try {
      const response = await fetch('/jifeng-api/support/requests', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const result = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(result.message || '提交失败，请稍后重试');

      status.className = 'form-status success';
      status.textContent = `已收到。受理编号：${result.referenceId}。请保存该编号以便后续查询。`;
      form.reset();
    } catch (error) {
      status.className = 'form-status error';
      status.textContent = error.message || '提交失败，请稍后重试';
    } finally {
      button.disabled = false;
      button.textContent = '提交请求';
    }
  });
})();
