from krita import Krita
def run():
    app=Krita.instance()
    print('KRITA_RUNNER_OK',app.version(),flush=True)
