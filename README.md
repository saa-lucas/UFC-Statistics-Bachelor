![Project Cover](assets/Apresentacao_Pitch-01.png)

# 📊 Digital Journalism: Mobile or Traffic Volume?
### A Comparative Analysis between UOL, G1, and Estadão

Project developed for the **CC0290 - Regression Models I** course, taught by Professor **Rafael Bráz Azevedo Farias** at the Federal University of Ceará (UFC).

## 👥 Team

* **Pedro Lucas Rodrigues de Oliveira Sá** (Data Science & Diagnostics)
* **Raquel Queiroz da Silva** (Pitch & Visual Communication)
* **Wagner Mendes Crispim** (Methodology & Modeling)

## 🎯 Objective

To investigate the association between the volume of views, the access device (Mobile or Desktop), and reading retention in three major Brazilian news portals: UOL, G1, and Estadão.

## 🛠️ Techniques Used

* Multiple Linear Regression
* Multicollinearity Diagnostics (Variance Inflation Factor - VIF)
* Analysis of Covariance (ANCOVA)
* Data Visualization and Interpretation in Python

---

## 🔍 Key Insights & Methodology

The core of our analysis revealed a severe statistical challenge: **Multicollinearity**. By calculating the Variance Inflation Factor (VIF), we discovered that in massive portals like UOL and G1, the Mobile traffic volume completely masked the independent effects of the variables. Estadão served as our natural control group.

![VIF Analysis](assets/Apresentacao_Pitch-07.png)

### Model Diagnostics: Residuals & Normality
To validate the reliability of our ANCOVA model and its P-values, we performed residual diagnostics. The tests (Omnibus and Jarque-Bera) and visual plots confirmed that the model's errors follow a normal distribution, securing our statistical inferences.

<p align="center">
  <img src="assets/residuals_histogram.png" width="45%" alt="Residuals Histogram" />
  <img src="assets/residuals_qqplot.png" width="45%" alt="QQ-Plot" />
</p>

## 🚀 Conclusions & Business Recommendations

Our findings prove that mobile audience retention is categorically superior, guiding targeted corporate investments, advertising strategies, and seasonal content planning.

![Conclusions](assets/Apresentacao_Pitch-17.png)

---

## 📁 Repository Structure

* `Relatorio_Tecnico.pdf`: Technical report specifying the intellectual contributions of the team members.
* `Apresentacao_Pitch.pdf`: Visual presentation developed for the project pitch.
* `Analise_Retencao_Comscore.ipynb`: Jupyter Notebook containing the complete analysis process, from data cleaning to regression models and ANCOVA.
* `Comscores_UOL_G1_Estadao.csv`: The raw dataset used in the study.
* `assets/`: Folder containing images and diagnostic plots used in this documentation.

## 🔗 Links

* **Google Colab (Interactive Notebook):** [Access Here](https://colab.research.google.com/drive/1GuxA5vyoD5EFkKfm3SN-R9mArqJ-yJVs?usp=sharing)
* **Canva Presentation (Pitch Deck):** [Access Here](https://canva.link/jmt657h5t73t67v)
