#import "lib.typ": conf

#let lang = sys.inputs.at("language", default: "it").trim()

#show: conf.with(
  title: [Heterogeneous Swarm],
  authors: (
    (
      name: "Lorenzo Debertolis",
      email: "lorenzo.debertolis@studio.unibo.it",
    ),
  ),
  date: "16/11/2025",
  language: lang,
)

#include lang + "/main.typ"
