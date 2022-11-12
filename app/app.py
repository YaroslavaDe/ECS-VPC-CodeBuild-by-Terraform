from flask import Flask, render_template
import random
app = Flask(__name__)


# list of images
images = [
  "https://img.global.news.samsung.com/global/wp-content/uploads/2022/09/IFA_Sketch_Save_Your_Energy_main7.gif"
]
@app.route('/')
def index():
  url = random.choice(images)
  return render_template('index.html', url=url)

if __name__ == "__main__":
  app.run(host="0.0.0.0")
