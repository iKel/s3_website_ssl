function handleButtonClick(buttonNumber) {
  const output = document.getElementById('output');
  const imageContainer = document.getElementById('imageContainer');
  
  if (buttonNumber === 3) {
    output.innerText = 'Button 3 was clicked!';
    imageContainer.style.display = 'block';
  } else {
    output.innerText = `Button ${buttonNumber} was clicked! \nnothing happened!`;
    imageContainer.style.display = 'none';
  }
}
