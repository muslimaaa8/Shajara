<!DOCTYPE html>
<html lang="uz">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">

<title>Менинг оилам шажараси</title>

<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>

<style>
body {
    background: #f5f1e8;
    font-family: Arial, sans-serif;
    text-align: center;
}

h1 {
    color: #526b45;
}

.diagram {
    background: white;
    padding: 30px;
    margin: 20px;
    border-radius: 15px;
    overflow-x: auto;
}

.mermaid {
    min-width: 900px;
}
</style>
</head>

<body>

<h1>🌳 Менинг оилам шажараси</h1>

<div class="diagram">
<pre class="mermaid">

graph TD

A["Катта бобо"] --- B["Катта буви"]

A & B --> C["Бобо"]
A & B --> D["Буви"]

C & D --> E["Ота"]

F["Она томони бобоси"] --- G["Она томони бувиси"]

F & G --> H["Она"]

E --- H

E & H --> I["Мен"]
E & H --> J["Укам"]

</pre>
</div>

<script>
mermaid.graph TD
A["Катта бобо"] --- B["Катта буви"]
A & B --> C["Бобо"]
A & B --> D["Буви"]
C & D --> E["Ота"]
F["Она томони бобоси"] --- G["Она томони бувиси"]
F & G --> H["Она"]
E --- H
E & H --> I["Мен"]
initialize({
    startOnLoad: true,
    theme: 'default',
    flowchart: {
        curve: 'basis'
    }
});
</script>

</body>
</html>
